(:
 :
 :  Copyright (C) 2019 Wolfgang Meier
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

module namespace facets="http://teipublisher.com/facets";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace facets-advanced="http://teipublisher.com/facets-advanced" at "facets-advanced.xql";
import module namespace facets-simple="http://teipublisher.com/facets-simple" at "facets-simple.xql";
import module namespace facets-common="http://teipublisher.com/facets-common" at "facets-common.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $facets:default-version := "-simple";

declare %private function facets:dispatch($function as xs:string, $args as array(*)) {
    let $version := if($config:facets-version = "") then "-simple" else $config:facets-version
    let $fn := function-lookup(xs:QName("facets" || $version || ":" || $function), array:size($args))
    let $fn := if (exists($fn)) then $fn
        else
            function-lookup(xs:QName("facets" || $facets:default-version || ":" || $function), array:size($args))
    return
        if (exists($fn)) then
            apply($fn, $args)
        else
            ()
};

declare function facets:translate($config as map(*), $lang as xs:string?, $label as xs:string) {
    facets-common:translate($config, $lang, $label)
};

declare function facets:sort($config as map(*), $lang as xs:string?, $facets as map(*)?) {
    facets:dispatch("sort", [$config, $lang, $facets])
};

declare function facets:print-table($config as map(*), $nodes as element()+, $values as xs:string*, $params as xs:string*) {
    facets:dispatch("print-table", [$config, $nodes, $values, $params])
};

declare function facets:display($config as map(*), $nodes as element()+) {
    facets:dispatch("display", [$config, $nodes])
};