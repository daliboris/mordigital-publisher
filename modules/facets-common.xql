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

module namespace facets-common="http://teipublisher.com/facets-common";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function facets-common:sort($config as map(*), $lang as xs:string?, $facets as map(*)?) {
    array {
        if (exists($facets)) then
            for $key in map:keys($facets)
            let $value := map:get($facets, $key)
            let $sortKey := facets-common:translate($config, $lang, $key)
            order by $sortKey ascending
            return
                map { $key: $value }
        else
            ()
    }
};


declare function facets-common:get-parameter($name as xs:string) {
    let $param := request:get-parameter($name, ())
    return
        if (exists($param)) then
            $param
        else
            let $fromSession := session:get-attribute($config:session-prefix || '.params')
            return
                if (exists($fromSession)) then
                    $fromSession?($name)
                else
                    ()
};

declare function facets-common:translate($config as map(*)?, $language as xs:string?, $label as xs:string) {
    if (exists($config) and map:contains($config, "output")) then
        let $fn := $config?output
        return
            if (function-arity($fn) = 2) then
                $fn($label, $language)
            else
                $fn($label)
    else
        $label
};