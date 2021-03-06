# This class is designed to work with a Mongoid model that has base_path and
# routes fields (where the routes field matches the govuk schema of an array
# of objects with path and type fields)
#
# It is designed to make it easy to find an item that matches a particular
# path that may exist as a base_path or within routes
class FindByPath
  attr_reader :model_class

  def initialize(model_class)
    @model_class = model_class
  end

  def find(path)
    matches = find_matching_items(path)
    matches.present? ? best_match(matches, path) : nil
  end

private

  def find_matching_items(path)
    model_class
      .or(base_path: path)
      .or(routes: { "$elemMatch" => { path: path, type: "exact" } })
      .or(routes: { "$elemMatch" => { :path.in => potential_prefixes(path), type: "prefix" } })
      .entries
  end

  def best_match(matches, path)
    base_path_match(matches, path) ||
      exact_route_match(matches, path) ||
      best_prefix_match(matches, path)
  end

  def potential_prefixes(path)
    paths = path.split("/").reject(&:empty?)
    (0...paths.size).map { |i| "/#{paths[0..i].join('/')}" }
  end

  def base_path_match(matches, path)
    matches.detect { |item| item.base_path == path }
  end

  def exact_route_match(matches, path)
    matches.detect do |item|
      item.routes.any? { |route| route["path"] == path && route["type"] == "exact" }
    end
  end

  def best_prefix_match(matches, path)
    prefixes = potential_prefixes(path)
    sorted = matches.sort_by do |item|
      best_match = item.routes
        .select { |route| route["type"] == "prefix" && prefixes.include?(route["path"]) }
        .sort_by { |route| -route["path"].length }
        .first

      -best_match["path"].length
    end
    sorted.first
  end
end
