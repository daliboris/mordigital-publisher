xquery version "3.1";

(:~
 : A set of custom helper functions to access the application context from
 : within a module. Functions are merged in config.xqm module.
 :)
module namespace custom-config="http://www.tei-c.org/tei-simple/custom-config";

(:
 : Display configuration for facets to be shown in the sidebar. The facets themselves
 : are configured in the index configuration, collection.xconf.
 :)
declare variable $custom-config:facets := [
    map {
        "dimension": "dictionary",
        "heading": "lex0.facets.dictionary",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "entry-type",
        "heading": "lex0.facets.entry-type",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "pos",
        "heading": "lex0.facets.pos",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "polysemy",
        "heading": "lex0.facets.polysemy",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "domain",
        "heading": "lex0.facets.domain",
        "max": 5,
        "hierarchical": false()
    },
    (:
    map {
        "dimension" : "domain-hierarchy",
        "heading": "lex0.facets.domain-hierarchy",
        "max": 5,
        "hierarchical": true()
    },
    :)
    map {
        "dimension" : "domain-contemporary",
        "heading": "lex0.facets.domain-contemporary",
        "max": 5,
        "hierarchical": true()
    },
    map {
        "dimension": "attitude",
        "heading": "lex0.facets.attitude",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "frequency",
        "heading": "lex0.facets.frequency",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "geographic",
        "heading": "lex0.facets.geographic",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "hint",
        "heading": "lex0.facets.hint",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "meaningType",
        "heading": "lex0.facets.meaningType",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "normativity",
        "heading": "lex0.facets.normativity",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "socioCultural",
        "heading": "lex0.facets.socioCultural",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "textType",
        "heading": "lex0.facets.textType",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "time",
        "heading": "lex0.facets.time",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "attestation",
        "heading": "lex0.facets.attestation",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "attestation-author",
        "heading": "lex0.facets.attestation-author",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "attestation-title",
        "heading": "lex0.facets.attestation-title",
        "max": 5,
        "hierarchical": false()
    },
    map {
        "dimension": "metamark",
        "heading": "lex0.facets.metamark",
        "max": 5,
        "hierarchical": false()
    }
];

declare variable $custom-config:login-domain := "eu.dariah.teilex0";

(:
    Maximum items returned for autocomplete function.
:)
declare variable $custom-config:autocomplete-max-items := 30;

(: 
    Function for formatting string for autocomplete.
:)
declare variable $custom-config:autocomplete-return-values := function($key, $count) {$key};

declare variable $custom-config:facets-version := "-advanced" (: () :);

declare variable $custom-config:query-facet-pattern := "^facet\[(.*)\]$$" (: () :);

declare function custom-config:template-filter($request as map(*), $item as map(*)) {
    contains($item?title, 'Lex-0')
    (: true() :)
};

declare function custom-config:template-sort($request as map(*), $item as map(*)) {
    $item?title
    (: 1 :)
};