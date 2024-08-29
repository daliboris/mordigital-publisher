(:
 :
 :  Copyright (C) 2023 Boris Lehečka
 :
 :  This program is free software: you can redistribute it and/or modify
 :  it under the terms of the GNU General Public License as published by
 :  the Free Software Foundation, either version 3 of the License, or
 :  (at your option) any later version.
 :
 :  This program is distributed in the hope that it will be useful,
 :  but WITHOUT ANY WARRANTY; without even the implied warranty of
 :  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 :  GNU General Public License for more details.
 :
 :  You should have received a copy of the GNU General Public License
 :  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)

xquery version "3.1";

module namespace lapi="http://teipublisher.com/api/teilex0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization"; 
declare namespace exist="http://exist.sourceforge.net/NS/exist";


import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace custom-config="http://www.tei-c.org/tei-simple/custom-config" at "custom-config.xqm";
import module namespace lexq="http://teipublisher.com/api/teilex0-query" at "teilex0-query.xql";
import module namespace capi="http://teipublisher.com/api/collection" at "lib/api/collection.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "../util.xql";

import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
import module namespace dapi="http://teipublisher.com/api/documents" at "lib/api/document.xql";

import module namespace rq="http://www.daliboris.cz/ns/xquery/request"  at "request.xql";


import module namespace lfacets="http://www.tei-c.org/tei-simple/query/tei-lex-facets" at "facets-tei-lex.xql";


import module namespace console="http://exist-db.org/xquery/console";

declare variable $lapi:debug := true();

declare variable $lapi:json-serialisation :=
        <output:serialization-parameters>
            <output:method value="json" />
            <output:indent value="yes" />
            <output:omit-xml-declaration value="yes" />
        </output:serialization-parameters>;

declare function lapi:project($request as map(*)) {
    let $format := $request?parameters?format
    let $result := if($format = "xml") then
            lapi:project-xml()
         else 
            lapi:project-json()
    return lapi:send-respnose($result, $format)
    (: return lapi:send-respnose($result, "xml") :)
};

declare %private function lapi:project-xml() {
    let $items := collection($config:data-default-metadata)//tei:TEI[@type='lex-0']
                    
    let $dictionary := for $item in $items
        return <dictionary xml:id="{$item/@xml:id}">
            {($item/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title,
            <file>{base-uri($item)}</file>)}
         </dictionary>
    return
        <project>{$dictionary}</project>
};

declare %private function lapi:project-json() {
    let $items := collection($config:data-default-metadata)//tei:TEI[@type='lex-0']
                    
    let $dictionary := for $item at $count in $items
        return <map key="dictionary-{$count}" xmlns="http://www.w3.org/2005/xpath-functions">
            {
                (
                <string key="xml:id">{data($item/@xml:id)}</string>,
                <string key="file">{base-uri($item)}</string>,                
                <array key="titles">
                {for $title in $item/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title
                    return 
                        (<map>
                            <string key="{data($title/@type)}">{data($title)}</string>
                        </map>)
                }
                </array>
                )
            }
         </map>

    let $project := <array xmlns="http://www.w3.org/2005/xpath-functions"><map>{$dictionary}</map></array>
    let $result := xml-to-json($project, map{"indent":true()})

    return $result
};


declare function lapi:version($request as map(*)) {
    let $format := $request?parameters?format
    let $json := json-doc($config:app-root || "/modules/teilex0-api.json")
    let $version := $json?info?version
    let $result := if($format = "xml") then
        <api version="{$version}" />
            else serialize( map {"api" : $version}, $lapi:json-serialisation)
    return lapi:send-respnose($result, $format)
};

declare function lapi:send-respnose($item as item()*, $format as xs:string) {
    let $content-type :=
    switch ($format)
        case "xml" return "application/xml"
        case "html" return "text/html"
        case "json" return "application/json"
        default  return "text/html"
    return
    (
    response:set-header("Content-Type", $content-type),
    $item
    )
};

(:
declare function lapi:dictionaries($request as map(*)) {  
    let $format := $request?parameters?format
    let $parts := $request?parameters?dictionary-parts

    return capi:list($request)
};
:)

declare function lapi:search($request as map(*)) { 
    
    (: <result name="lapi:search" type="TODO" />  :)
    
    let $exist-db-query := lexq:get-exist-db-query-xml($request)
    
    let $log := if($lapi:debug) 
        then (console:log("[lapi:search] $query:"),
                console:log($exist-db-query)) 
        else ()
    
    let $max-hits := $config:maximum-hits-limit

    let $is-query-empty := (
            (empty($request?parameters?query) or $request?parameters?query = '') 
            and empty($request?parameters("query-advanced[1]"))
        ) 
            or empty($exist-db-query)

    return
    if ($is-query-empty)
    then
        let $hitsAll := session:get-attribute($config:session-prefix || ".hits")
        let $hitCount := count($hitsAll)
        let $hits := if ($max-hits > 0 and $hitCount > $max-hits) then subsequence($hitsAll, 1, $max-hits) else $hitsAll

        (:lapi:show-hits($request, session:get-attribute($config:session-prefix || ".hits"), session:get-attribute($config:session-prefix || ".docs")):)
        return if($request?parameters?format = "xml") then
                lapi:show-hits-xml($request, $hits, session:get-attribute($config:session-prefix || ".docs"), "div", "http://www.tei-c.org/ns/1.0")
            else
             lapi:show-hits-html($request, $hits, session:get-attribute($config:session-prefix || ".docs"))
    else
        (:Otherwise, perform the query.:)
        (: Here the actual query commences. This is split into two parts, the first for a Lucene query and the second for an ngram query. :)
        (:The query passed to a Luecene query in ft:query is an XML element <query> containing one or two <bool>. 
        The <bool> contain the original query and the transliterated query, as indicated by the user in $query-scripts.:)
       let $hitsAll :=
                let $qry := lexq:parse-exist-db-query($exist-db-query)
                return  lapi:execute-query-return-hits($qry?query, $qry?full-options, $exist-db-query/sort/@field)

        let $hitCount := count($hitsAll)
        (:Store the result in the session.:)
        let $store := (
            session:set-attribute($config:session-prefix || ".hits", $hitsAll),
            session:set-attribute($config:session-prefix || ".hitCount", $hitCount),
            session:set-attribute($config:session-prefix || ".search", if (empty($request?parameters?query))
             then () else xmldb:decode($request?parameters?query)),
            session:set-attribute($config:session-prefix || ".field", $request?parameters?field),
            session:set-attribute($config:session-prefix || ".position", $request?parameters?position),
            session:set-attribute($config:session-prefix || ".docs", $request?parameters?ids)
        )
        let $hits := if ($max-hits > 0 and $hitCount > $max-hits) then 
            subsequence($hitsAll, 1, $max-hits) else $hitsAll
        
        
        return if($request?parameters?format = "xml") then
                lapi:show-hits-xml($request, $hits, $request?parameters?ids, "div", "http://www.tei-c.org/ns/1.0")
            else
                lapi:show-hits-html($request, $hits, $request?parameters?ids)
   
};
declare %private function lapi:get-highlight-value($request as map(*)) {
(: if(empty($request?parameters?highlight)) 
    then false()
else if($request?parameters?highlight = "on") 
    then true() 
    else  xs:boolean($request?parameters?highlight) :)
xs:boolean($request?parameters?highlight)
};

declare function lapi:facets($request as map(*)) { 
    (: <result name="lapi:facets" type="TODO" /> :)

    let $hits := session:get-attribute($config:session-prefix || ".hits")
    (: TODO? 
    let $result := subsequence($hits, $request?parameters?start, $request?parameters?per-page)
    :)
    let $result := $hits
    let $highlight := lapi:get-highlight-value($request)
    let $expanded :=
        if ($highlight and exists($result)) then
            util:expand($result)
        else
            $result
    return if($request?parameters?format = "xml") then
    
    let $params := rq:get-all-parameters($request)
    let $f := function($k, $v) {<item value="{$k}" count="{$v}" />}
    let $facet-dimension := for $dim in $config:facets?*
        let $facets-map := ft:facets($hits, $dim?dimension, 5)
        return <dimension name="{$dim?dimension}" parameter="{request:get-parameter("facet[" || $dim?dimension || "]", ())}">
            <facet>{map:for-each($facets-map, $f)}</facet>
        </dimension>
    let $facets := <facets count="{count($config:facets?*)}">
                        <dimensions>{$facet-dimension}</dimensions>
                    </facets>
    return
        (response:set-header("Content-Type", "application/xml"),
        <result>{($params, $facets, <hits count="{count($expanded)}">{$expanded}</hits>)}</result>)
    
    else if(count($hits) > 0) then
    
        <div>
        {
            for $config in $config:facets?*
            return
                lfacets:display($config, $hits)
        }
        </div>
        else ()
    
 };


declare function lapi:domains($request as map(*)) { <result name="lapi:domains" type="TODO" /> };

declare function lapi:autocomplete($request as map(*)) {
     (: <result name="lapi:autocomplete" type="TODO" />  :)

    let $q := request:get-parameter("query", ())
    let $type := request:get-parameter("field", "entry")
    let $doc := request:get-parameter("ids", ())
    let $position := request:get-parameter("position", "start")
    let $items :=
        if ($q) then
            lapi:autocomplete($doc, $type, $q)
        else
            ()
    return
        array {
            for $item in $items
            return
                map {
                    "text": $item,
                    "value": $item
                }
        }

};

declare function lapi:autocomplete($doc as xs:string?, $fields as xs:string+, $q as xs:string) {
    let $max-items := $config:autocomplete-max-items
    let $f := $config:autocomplete-return-values
    let $index := "lucene-index"

    let $lower-case-q := lower-case($q)
    for $field in $fields
    let $field := config:get-index-field-for-localized-values($field)
    return
        switch ($field)
            case "author" return
                collection($config:data-root)/ft:index-keys-for-field("author", $lower-case-q,
                    $f, $max-items)
            case "file" return
                collection($config:data-root)/ft:index-keys-for-field("file", $lower-case-q,
                    $f, $max-items)
            case "text" return
                if ($doc) then (
                    doc($config:data-root || "/" || $doc)/util:index-keys-by-qname(xs:QName("tei:div"), $lower-case-q,
                        $f, $max-items, $index),
                    doc($config:data-root || "/" || $doc)/util:index-keys-by-qname(xs:QName("tei:text"), $lower-case-q,
                        $f, $max-items, $index)
                ) else (
                    collection($config:data-root)/util:index-keys-by-qname(xs:QName("tei:div"), $lower-case-q,
                        $f, $max-items, $index),
                    collection($config:data-root)/util:index-keys-by-qname(xs:QName("tei:text"), $lower-case-q,
                        $f, $max-items, $index)
                )
            case "head" return
                if ($doc) then
                    doc($config:data-root || "/" || $doc)/util:index-keys-by-qname(xs:QName("tei:head"), $lower-case-q,
                        $f, $max-items, $index)
                else
                    collection($config:data-root)/util:index-keys-by-qname(xs:QName("tei:head"), $lower-case-q,
                        $f, $max-items, $index)
            
            
            case "entry" return
                if ($doc) then
                    doc($config:data-default || "/LeDIIR-" || $doc || ".xml")/util:index-keys-by-qname(xs:QName("tei:entry"), $lower-case-q,
                        $f, $max-items, $index)
                else
                    collection($config:data-default)/util:index-keys-by-qname(xs:QName("tei:entry"), $lower-case-q,
                        $f, $max-items, $index)
            case "objectLanguage"
            case "targetLanguage"
            case "lemma" 
            case "definition"
            case "example"
            case "pos"
            case "attitude"
            case "domain" 
            case "socioCultural"
            case "textType"
            case "time"
            case "attestation"
            return
                if ($doc) then
                    doc($config:data-default || $doc || ".xml")/ft:index-keys-for-field($field, $lower-case-q,
                    $f, $max-items)
                else
                    collection($config:data-default)/ft:index-keys-for-field($field, $lower-case-q,
                    $f, $max-items)       
            
            
            
            default return
                collection($config:data-root)/ft:index-keys-for-field("title", $lower-case-q,
                    $f, $max-items)
};

declare function lapi:browse($request as map(*)) { <result name="lapi:browse" type="TODO" /> };

declare function lapi:contents($request as map(*)) { <result name="lapi:contents" type="TODO" /> };

declare function lapi:dictionaries($request as map(*)) { <result name="lapi:dictionaries" type="TODO" />};

declare function lapi:dictionary-contents($request as map(*)) { <result name="lapi:dictionary-contents" type="TODO" /> };

declare function lapi:dictionary-entries($request as map(*)) { <result name="lapi:dictionary-entries" type="TODO" /> };

declare function lapi:dictionary-entry($request as map(*)) { <result name="lapi:dictionary-entry" type="TODO" /> };



declare %private function lapi:show-hits-xml($request as map(*), $hits as item()*, $docs as xs:string*) {
    response:set-header("pb-total", xs:string(count($hits))),
    response:set-header("pb-start", xs:string($request?parameters?start)),
    response:set-header("pb-docs", string-join($docs, ';')),
    response:set-header( "Content-Type", "application/xml" ),
    let $highlight := lapi:get-highlight-value($request)
    let $config := ()
    let $result := subsequence($hits, $request?parameters?start, $request?parameters?per-page)
    let $expanded :=
        if ($highlight and exists($result)) then
            util:expand($result)
        else
            $result
    return $expanded
};

declare %private function lapi:show-hits-xml($request as map(*), $hits as item()*, $docs as xs:string*, $containter as xs:string, $namespace as xs:string) {
    let $result := lapi:show-hits-xml($request, $hits, $docs)
    let $contained := element {QName($namespace, $containter)} {$result}
    return <result xmlns:exist="http://exist.sourceforge.net/NS/exist">{$contained}</result>
};


declare %private function lapi:show-hits-html($request as map(*), $hits as item()*, $docs as xs:string*) {
    response:set-header("pb-total", xs:string(count($hits))),
    response:set-header("pb-start", xs:string($request?parameters?start)),
    let $query-start-time := util:system-time()
    let $highlight := lapi:get-highlight-value($request)
    let $config := if(empty($hits)) 
        then config:default-config(()) 
        else tpu:parse-pi(root($hits[1]), $request?parameters?view)
    let $result := subsequence($hits, $request?parameters?start, $request?parameters?per-page)
    let $expanded :=
        if ($highlight and exists($result)) then
            util:expand($result)
        else
            $result
    let $log := if($lapi:debug) then (
            console:log("api:show-hits-html: ODD" || $config?odd),
            console:log("api:show-hits-html: $highlight and $result: " || ($highlight and exists($result)))
            )
             else ()
    let $result-html := lapi:get-html($expanded, $request, $config)
    let $log := lapi:log-duration($query-start-time, "[lapi:show-hits-html] after lapi:get-html:")
    return 
        $result-html
};

declare %private function lapi:execute-query-return-hits($query as item(), $options as item()?, $sort as xs:string? ) {
 
 lapi:execute-query-return-hits($query, $options, $sort, ())

 };

declare %private function lapi:execute-query-return-hits($query as item(), $options as item()?, $sort as xs:string?,
    $hits as element(tei:entry)* ) {

    let $console := if($lapi:debug) then 
        (
            console:log("[lapi:execute-query-return-hits] $query:"),
            console:log($query),
            console:log("[lapi:execute-query-return-hits] $options:"),
            console:log($options),
            console:log("[lapi:execute-query-return-hits] $sort:"),
            console:log($sort)
        )
        else ()

    let $query-start-time := util:system-time()
    let $ft := if(empty($hits)) then
            collection($config:data-default-search)//tei:entry[not(parent::tei:entry)][ft:query(., $query, $options)]
        else 
            $hits[ft:query(., $query, $options)]
    (: let $result := $ft :)
    let $console := if($lapi:debug) then console:log("[lapi:execute-query-return-hits] $sort: " || $sort || "; empty or '': " || (empty($sort) or $sort = '')) else ()
    (: let $console := if($lapi:debug) then console:log("ft") else ()
    let $console := if($lapi:debug) then console:log($ft) else () :)
    let $result := if(empty($sort) or $sort = '') then $ft
         else if($sort = 'score') then
         for $f in $ft order by ft:score($f) descending return $f
         (: else if($sort = 'lemma' or empty($sort)) then $ft :)
         else for $f in $ft order by ft:field($f, $sort) ascending return $f

    let $log := if($lapi:debug) then lapi:log-duration($query-start-time, "[lapi:execute-query-return-hits] after sort:") else ()

    return
        $result

};

(:
 See dapi:print in /modules/lib/api/document.xql 
:)
declare function lapi:get-html($hits as item()*, $request as map(*), $config) {
  lapi:get-html($hits, $request, $config, "print")
};


(:
 See dapi:generate-html in /modules/lib/api/document.xql 
:)

declare function lapi:get-html($hits as item()*, $request as map(*), $config, $outputMode as xs:string) {
    let $addStyles :=
        for $href in $request?parameters?style
        return
            <link rel="Stylesheet" href="{$href}"/>
    let $addScripts :=
        for $src in $request?parameters?script
        return
            <script src="{$src}"></script>
    let $xml := <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{$hits}</tei:TEI>
    (: set root parameter to the root document of hits :)
    let $root := if(empty($hits)) then $xml else root($hits[1])
    (:    let $out := $pm-config:web-transform($xml, map { "root": $root, "webcomponents": 7 }, $config?odd):)
    let $out :=  if ($outputMode = 'print') then
                            $pm-config:print-transform($xml, map { "root": $root, "webcomponents": 7 }, $config?odd)
                        else
                            $pm-config:web-transform($xml, map { "root": $root, "webcomponents": 7 }, $config?odd)
    let $styles := ($addStyles,
                    if (count($out) > 1) then $out[1] else (),
                        <link rel="stylesheet" type="text/css" href="transform/{replace($config?odd, "^.*?/?([^/]+)\.odd$", "$1")}.css"/>
                    )

    (:   
    let $log := console:log("lapi:get-html: styles count=" || count($styles) || ", content: " || $styles[1])
    let $log := console:log("lapi:get-html: $config?odd=" || $config?odd)
    let $log := console:log("lapi:get-html: $parameters?root")
    let $log := console:log(($out[2], $out[1])[1]) 
    :)
    

    let $main := <html>{($out[2], $out[1])[1]}</html>
    return
      (:        dapi:postprocess(($out[2], $out[1])[1], $styles, $config?odd, $request?parameters?base, $request?parameters?wc):)
      (: dapi:postprocess(($out[2], $out[1])[1], $styles, $addScripts, $request?parameters?base, $request?parameters?wc) :)
      dapi:postprocess($main, $styles, $addScripts, $request?parameters?base, $request?parameters?wc)
};


declare %private function lapi:log-duration($query-start-time as xs:time, $message as xs:string?) {
    let $query-end-time := if($lapi:debug) then util:system-time() else ()
    let $query-duration := if($lapi:debug) then ($query-end-time - $query-start-time) div xs:dayTimeDuration('PT1S') else ()
    return if($lapi:debug) then console:log($message || " " || $query-duration) else ()
};