# The Content Item Format

A content item consists of a set key/value pairs. Different key/value pairs are
present or required, depending on the context. The three contexts are:

 - storing: content items being sent to the content store.
 - retrieving: content items being retrieved from the content store.
 - notifying: Messages notifying listeners about changes to content items.

Examples of content items as sent to the content store can be found in
[`input_examples`](input_examples/). Examples of content items being retrieved
from the content store API can be found in
[`output_examples`](output_examples/).

# Details of each field

## `base_path`

A string. Present in all contexts.

The absolute path of the content on GOV.UK. This uniquely identifies the
content within the content store and allows the content store to answer the
question "what is at this URL?".

## `format`

A string. Present in all contexts.

The format of the content. This determines how the contents of the `details`
field should be interpreted by the public-facing application responsible for
rendering the content on GOV.UK.

Some formats are explicitly handled by the content store, and expect a different
set of fields than those listed below.

 - `gone`: A content item which has [gone away](gone_item.md)
 - `redirect`: A content item which has [been redirected](redirect_item.md)
 - `placeholder*`: A temporary [placeholder](placeholder_item.md) for a content item.

## `content_id`

A UUID string as described in [RFC 4122](http://www.ietf.org/rfc/rfc4122.txt).
Present only in the storing context.

For example: `"30737dba-17f1-49b4-aff8-6dd4bff7fdca"`.

This is a unique identifier for the piece of content, allocated by the
publishing application. It is used as the reference with which content items can
reference other content items (see the `links` field in the input/output
examples).

If translations of a content item exist, they should all use the same
`content_id` and be distinguished by their `locale`. This allows the content
store to automatically generate a list of `available_translations` for each
content item, and to choose the most appropriate available translation of an
item when resolving related links.

The content store does not enforce the uniqueness of (`content_id`, `locale`)
tuples within the store, so more than one content item may exist in the
content store for the same (`content_id`, `locale`) pair. This will usually
only ever be temporary during the creation of a redirect to ensure that the
new content is available before the redirect replaces the old content.

## `title`

A string. Present in all contexts.

The title for the content. This will be used, for example, for the HTML title
of the content when formatted as HTML, but may also be used when linking to the
content (eg, in search results).

## `description`

A string. Present in all contexts.

The description of the content. This will be used, for example, for the HTML
meta-description of the content when formatted as HTML, but may also be used
when linking to the content (eg, in search results).

## `need_ids`

An array of strings. Present in all contexts.

An array of need ids associated with the content. These should be strings
(though will typically be integers encoded as decimal strings); eg "100001".

Note: currently needs are not published on GOV.UK, so there won't be an entry
in the content store for them. If this changes in future, the `need_ids` field
may be replaced by using the `links` field to store this relation.

## `locale`

The I18n locale code for the content item. Present in all contexts.

This specifies the language of the content. It is an optional field when adding
content items to the content store, but the content store will default it to
the default language (English, represented by the code `en`) if it is not
explicitly set.

The field uses [IETF language
tags](http://en.wikipedia.org/wiki/IETF_language_tag); though only a small set
of values are allowed (defined in the `config.i18n.available_locales` setting).

Locales are always in lowercase.  We use the plain 2 letter [ISO
693-1](http://en.wikipedia.org/wiki/ISO_639-1) codes for many languages (eg,
`en` is "English").  We append two-letter [ISO
3166-1](http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country codes in some
cases (eg, `zh-hk` is "Chinese, Hong Kong variant with traditional characters")
and append three-digit [UN M.49](http://en.wikipedia.org/wiki/UN_M.49)
geographical region codes in other cases (eg, `es-419` is "Spanish appropriate
for the Latin America and Caribbean region").

## `public_updated_at`

ISO 8601 formatted timestamp. Present in all contexts.

This is the update date that should be surfaced to the user. This is used for
sorting documents by update date. It should change when there is a major
update and should not change for a minor update.

## `details`

A hash. Present in all contexts.

This hash contains information representing the main content of the content
item. The meaning of the data here is dependent on the value of the `format`
field. The interpretation of keys which exist here should be consistent for a
given format (though there may be optional ones for each format).

## `links`

A hash of `link_type => list_of_links`.

Present in all contexts, but representations vary.

The `link_type` is a string which describes the relationship or type of
related item.

The `list_of_links` is an array of content items, order is preserved. In the
storing context, content items are represented by their content ids. In the
retrieving context, content items are expanded (see [below](#representation-of-content-item-links-in-different-contexts)
for details).

You may link to items which haven't been published yet (ie. which are not yet
present in the content store). In that case, the items which are not published
yet will be omitted from the content store output in the `retrieving`
context.

The interpretation of the `link_type` is format-dependent, although it's
recommended to follow these rules of thumb:

- when linking to another type of content item, `link_type` should be the
  plural noun for the content format, e.g. `organisations`
- for general related links use the `related` link_type
- be careful of relying on the order of links to imply a nuance or distinction
  in a relationship (such as a primary organisation or section). Use a separate
  `link_type` instead.

An example:

    "links": {
      "lead_organisation": ['ORG-CONTENT-ID'],
      "organisations": ['ORG-CONTENT-ID', 'ANOTHER-ORG-CONTENT-ID'],
      "topics": ['TOPIC-CONTENT-ID'],
      "available_translations": [... automatically generated ...]
    }

The `available_translations` link type is special because it is automatically
generated by the content store. It lists the available translations of the
content item, ordered alphabetically by locale.

If duplicate items exist with the same (`content_id`, `locale`), the content
store will use the newest one.

For convenience, a self-referential link is included as well. If you try to
post a content item with `available_translations` in the `links` hash, you'll
get an error.

### Representation of content item links in different contexts

In the `storing` context, the items are UUID strings.

In the `notifying` context, the items are hashes containing: (TODO: confirm)
 - `content_id`: The Content ID of the linked content item
 - `base_path`: The base path of the content item

In the `retrieving` context, the items are hashes containing:
 - `title`: The title of the content item
 - `base_path`: The base path of the content
 - `api_url`: The URL at which the content item is retrievable from the content
              store
 - `web_url`: The public-facing URL for the piece of content
 - `locale`: The locale code of the item

## `updated_at`

ISO 8601 formatted timestamp. Present in retrieving and notifying contexts.

Note: This field is set by the content store whenever a item is created or
modified in it.

It contains the timestamp at which the content was last modified in any way.
This is suitable to be used for update versioning.

## `publishing_app`

A string. Present only in storing context.

This is the name of the application responsible for publishing the content to
the content store. This should be resolvable with
`Plek.find(publishing_app)`.

## `rendering_app`

A string. Present only in storing context.

The is the name of the application responsible for rendering the content on
GOV.UK. It is passed to the router when the content store registers the routes
for the content. This should be resolvable with `Plek.find(rendering_app)`.

## `routes`

An array of hashes. Present only in storing context.

This holds the routes associated with the content item. Each hash in the array
contains a path and a routing type. See
[`route_registration`](route_registration.md) for more details.

## `redirects`

An array of hashes. Present only in storing context.

The redirects from old paths associated with the content item. Each hash in the
array contains an original path, a routing type, and an optional destination
path. See [`route_registration`](route_registration.md) for
more details.

TODO: Currently, redirects for normal content can be registered with the
content item itself. We need to decide if this is what we want, or whether
redirects are only included in `redirect` content items.

## `update_type`

A string. Present in storing and notifying contexts.

This indicates the type of update that was made to the content item.
It must be one of:

 - 'major' - major changes to a piece of content.
 - 'minor' - changes which don't affect the meaning of the
   content, eg typo correction.
 - 'republish' - useful in situations such as when the data
   structure has changed.

Other types may be added in future, the content store will just pass them through
to the fanout.

## `state`

A string. Must be one of 'draft' or 'live'.

Publishing applications can control whether to show content only on the
draft stack by indicating that in the 'state' field:

- draft: will cause content to appear only on the draft site,
- live: will cause content to appear on the draft as well as live site.
