/* Select all asset-informations and the the nodelabel */
select 
	node.nodelabel,assets.* 
from 
	assets, node
where 
	assets.nodeid = node.nodeid
order by 
	assets.nodeid
