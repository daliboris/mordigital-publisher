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

module namespace facets="http://teipublisher.com/facets-simple";

import module namespace facets-common="http://teipublisher.com/facets-common" at "facets-common.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";


declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function facets:print-table($config as map(*), $nodes as element()+, $values as xs:string*, $params as xs:string*) {
    let $all := facets-common:get-parameter("all-" || $config?dimension)
    let $lang := tokenize(facets-common:get-parameter("language"), '-')[1]
    let $count := if ($all) then 50 else $config?max
    let $facets :=
        if ($all) then
            if (exists($values)) then
                ft:facets($nodes, $config?dimension, (), $values)
            else
                ft:facets($nodes, $config?dimension, ())
        else
            if (exists($values)) then
                ft:facets($nodes, $config?dimension, $count, $values)
            else
                ft:facets($nodes, $config?dimension, $count)
    return
        if (map:size($facets) > 0) then
            <table>
            {
                array:for-each(facets-common:sort($config, $lang, $facets), function($entry) {
                    map:for-each($entry, function($label, $freq) {
                        let $content := facets-common:translate($config, $lang, $label)
                        return
                        <tr>
                            <td>
                                <paper-checkbox class="facet" name="{config:facet-name($config?dimension)}" value="{$label}">
                                    { if ($label = $params) then attribute checked { "checked" } else () }
                                    {
                                        <pb-i18n key="{$content}">{$content}</pb-i18n>
                                    }
                                </paper-checkbox>
                            </td>
                            <td>{$freq}</td>
                        </tr>,
                        if (empty($params)) then
                            ()
                        else
                            let $nested := facets:print-table($config, $nodes, ($values, head($params)), tail($params))
                            return
                                if ($nested and head($params) eq $label) then
                                    <tr class="nested">
                                        <td colspan="2">
                                        {$nested}
                                        </td>
                                    </tr>
                                else
                                    ()
                            })
                })
            }
            </table>
        else
            ()
};

declare function facets:display($config as map(*), $nodes as element()+) {
    let $params := facets-common:get-parameter("facet-" || $config?dimension)
    let $lang := tokenize(facets-common:get-parameter("language"), '-')[1]
    let $table := facets:print-table($config, $nodes, (), $params)

    let $maxcount := 50
    (: maximum number shown :)
    let $max := head(($config?max, 50))

    (: facet count for current values selected :)
    let $fcount :=
    map:size(
     if (count($params)) then
            ft:facets($nodes, $config?dimension, $maxcount, $params)
        else
            ft:facets($nodes, $config?dimension, $maxcount)
    )

    where $table
    return (
        <div class="facet-dimension" data-dimension="facet-{$config?dimension}">
            <h3><pb-i18n key="{$config?heading}">{$config?heading}</pb-i18n>
             {
                if ($fcount > $max) then
                    <paper-checkbox class="facet" name="all-{$config?dimension}">
                        { if (facets-common:get-parameter("all-" || $config?dimension)) then attribute checked { "checked" } else () }
                        <pb-i18n key="facets.show">Show top 50</pb-i18n>
                    </paper-checkbox>
                else
                    ()
            }
            </h3>
            <div class="facet-block">
            {
                $table,
                (: if config specifies a property "source", output combo-box :)
                if (map:contains($config, "source")) then
                    (: use source as URL to API endpoint from which to retrieve possible values :)
                    <pb-combo-box source="{$config?source}" close-after-select="" placeholder="{$config?heading}"
                        >
                        <select multiple="">
                        {
                            for $param in facets-common:get-parameter("facet-" || $config?dimension)
                            let $label := facets-common:translate($config, $lang, $param)
                            return
                                <option value="{$param}" data-i18n="{$label}" selected="">{$label}</option>
                        }
                        </select>
                    </pb-combo-box>
                else
                    ()
            }
            </div>
        </div>
    )
};