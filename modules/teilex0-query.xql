xquery version "3.1";

module namespace lexq="http://teipublisher.com/api/teilex0-query";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization"; 

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace custom-config="http://www.tei-c.org/tei-simple/custom-config" at "custom-config.xqm";

import module namespace rq="http://www.daliboris.cz/ns/xquery/request"  at "request.xql";
import module namespace qrp="https://www.daliboris.cz/ns/xquery/query-parser/1.0"  at "query-parser-lucene.xql";
import module namespace edq = "http://www.daliboris.cz/schema/ns/xquery" at "query-parser-exist-db.xql"; 

import module namespace console="http://exist-db.org/xquery/console";

declare variable $lexq:debug := true();

declare function lexq:parse-exist-db-query($input as element(exist-db-query)) as map(*) {
    edq:parse-exist-db-query($input)
};

declare %private function lexq:get-lucene-query($parameter as element(parameter)*) {
  qrp:get-query-options(
    ($parameter[@name='query-advanced']/. | $parameter[@name='query']/.), 
    $parameter[@name='position']/., 
    $parameter[@name='field']/., 
    $parameter[@name='condition']/.
    )
};

declare %private function lexq:get-lucene-query-for-chapter($parameter as element(parameter)*) {
  qrp:get-query-options(
    <parameter name="query">{$parameter[@name='chapter']/value}</parameter>, 
    <parameter name="position"><value>exactly</value></parameter>, 
    <parameter name="field"><value>chapter</value></parameter>,
    ()
    )
};
declare %public function lexq:get-exist-db-query-xml($request as map(*), $sort-field as element()?) as element()* { 
    let $parameters := rq:get-all-parameters($request)
    (: let $console := console:log($parameters) :)
    let $sort := if(empty($parameters/parameter[@name='sort']/value) or $parameters/parameter[@name='sort']/value = '') 
        then ($sort-field, $config:default-search-sort-field)[1]
        else <sort field="{$parameters/parameter[@name='sort']/value}" />
    
    let $log := if($lexq:debug) then console:log("[lexq:get-exist-db-query-xml]" || " $sort/@field :: " || $sort/@field)  else ()

    let $hasQuery := not(empty($parameters/parameter[@name='query']/value[node()]))
    let $hasAdvancedQuery := not(empty($parameters/group/parameter[@name='query-advanced']/value[node()]))
    let $hasChapter := not(empty($parameters/parameter[@name='chapter']/value[node()]))
    let $lucene := if($hasChapter and $hasQuery and not($hasAdvancedQuery)) then
            (
            lexq:get-lucene-query($parameters/parameter[@name=('query', 'field', 'position')])
            , lexq:get-lucene-query-for-chapter($parameters/parameter[@name=('chapter')])
            )
         else if ($hasChapter) then
            lexq:get-lucene-query-for-chapter($parameters/parameter[@name=('chapter')])
        else if($hasQuery) then
        lexq:get-lucene-query($parameters/parameter[@name=('query', 'field', 'position')])
        else
        for $group in $parameters/group[parameter[@name='query-advanced'][node()]]
        order by $group/@name
        return lexq:get-lucene-query($group/parameter)
    let $facets := lexq:get-facets-values($request)
    let $combined := qrp:combine-queries($lucene)
    let $exist-db-query := if (empty($combined)) then () else <exist-db-query>{($combined, $facets, $sort)}</exist-db-query>
    (: return  ($parameters, <lucene>{$lucene}</lucene>, $exist-db-query) :)
    return $exist-db-query
};

declare %public function lexq:get-exist-db-query-xml($request as map(*)) as element()* {
    lexq:get-exist-db-query-xml($request, ())
};

declare %private function lexq:get-facets-values($request as map(*)) as element(facets)? {
    let $item-name := "facet"
    let $items-name := "facets"
    let $parameters := rq:get-all-parameters($request)
    let $items := $parameters/group[@name=$item-name]/parameter
    let $items := if(empty($items)) then ()
        else element {$items-name} {
                for $i in $items return 
                    element {$item-name} {
                        $i/@*,
                        $i/node()
                    }
                }
    return $items
};
