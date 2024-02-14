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


import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace custom-config="http://www.tei-c.org/tei-simple/custom-config" at "custom-config.xqm";

import module namespace capi="http://teipublisher.com/api/collection" at "lib/api/collection.xql";

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
    let $items := collection($config:data-default)//tei:TEI[@type='lex-0']
                    
    let $dictionary := for $item in $items
        return <dictionary xml:id="{$item/@xml:id}">
            {($item/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title,
            <file>{base-uri($item)}</file>)}
         </dictionary>
    return
        <project>{$dictionary}</project>
};

declare %private function lapi:project-json() {
    let $items := collection($config:data-default)//tei:TEI[@type='lex-0']
                    
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

declare function lapi:search($request as map(*)) { <result name="lapi:search" type="TODO" /> };

declare function lapi:facets($request as map(*)) { <result name="lapi:facets" type="TODO" /> };

declare function lapi:domains($request as map(*)) { <result name="lapi:domains" type="TODO" /> };

declare function lapi:autocomplete($request as map(*)) { <result name="lapi:autocomplete" type="TODO" /> };

declare function lapi:browse($request as map(*)) { <result name="lapi:browse" type="TODO" /> };

declare function lapi:contents($request as map(*)) { <result name="lapi:contents" type="TODO" /> };

declare function lapi:dictionaries($request as map(*)) { <result name="lapi:dictionaries" type="TODO" />};

declare function lapi:dictionary-contents($request as map(*)) { <result name="lapi:dictionary-contents" type="TODO" /> };

declare function lapi:dictionary-entries($request as map(*)) { <result name="lapi:dictionary-entries" type="TODO" /> };

declare function lapi:dictionary-entry($request as map(*)) { <result name="lapi:dictionary-entry" type="TODO" /> };
