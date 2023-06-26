SELECT
I.serial_number as 'Serial Number',
I.id as 'Item ID',
I.parent_id as 'Container Item ID (If Applicable)',
IT.name AS 'Item Name',
EPGVO.value AS 'Golden VITM',
DATE(IR.timestamp) AS 'Date Recieved In Original Location',
DATE(ITS.timestamp) AS 'Date Shipped to OKC', 
DATE(IOQ.timestamp) AS 'Date Sent into Quarantine', 
ITS.destination_street_address AS 'Destination Street Address',
ITS.destination_city AS 'Desintation City',
ITS.destination_state AS 'Destination State',
IOQ.data AS 'Quarantine Notes',
CASE WHEN DATE(IOR.timestamp) >= DATE(IOQ.timestamp) THEN DATE(IOR.timestamp) ELSE NULL END AS 'Quarantine Release Date (If Applicable)', -- date released from quarantine
LSF.human_description AS 'Quarantine Destination'

FROM
spiers_one.items AS I
    LEFT JOIN spiers_one.item_operations AS IOS ON IOS.id = (SELECT MAX(id) FROM spiers_one.item_operations WHERE item_id = I.id AND item_operation_type_id = 60) -- most recent shipments
    LEFT JOIN spiers_one.items_shipped AS ITS ON ITS.id = IOS.data
    LEFT JOIN spiers_one.locations AS LSF ON LSF.id = ITS.location_id 
    LEFT JOIN spiers_one.item_operations AS IOQ ON IOQ.id = (SELECT MAX(id) FROM spiers_one.item_operations WHERE item_id = I.id AND item_operation_type_id = 97) -- quarantine operation
    LEFT JOIN spiers_one.item_status_types AS IST ON IST.id = I.status_id
	LEFT JOIN spiers_external_interface.external_properties AS EPGVO ON EPGVO.id = (SELECT MAX(id) FROM spiers_external_interface.external_properties WHERE item_id = I.id AND external_property_id = 135) -- added this because it was in sample query
	LEFT JOIN spiers_external_interface.gm_bolt_recall_core_populations AS GM ON GM.serial_number = I.serial_number 
    LEFT JOIN spiers_one.item_operations as IOR on IOR.id = (SELECT MAX(id) FROM spiers_one.item_operations WHERE item_id = I.id AND item_operation_type_id = 100)-- assuming most recent quarantine release is after most recent quarantine
	LEFT JOIN spiers_one.items_received as IR on IR.id = (SELECT MAX(id) FROM spiers_one.items_received WHERE item_id = I.id AND location_id in (9997, 10009, 10010, 10011, 10012, 10013, 10014, 10015, 10016))
	LEFT JOIN spiers_one.item_types AS IT ON I.item_type_id = IT.id
WHERE
I.business_unit_id IN (2) AND
    I.status_id IN (6) AND -- quarantine 
    I.item_type_id IN (133, 141, 580, 946, 1314) AND -- bolts
    LSF.facility_id = 12 AND -- from Vegas
    ITS.destination_state = 'Oklahoma' AND -- to Oklahoma
    build_priority = 4 AND -- population = 4 
    DATE(IOQ.timestamp) BETWEEN DATE_SUB(DATE(ITS.timestamp), INTERVAL 3 MONTH) 
    AND DATE_ADD(DATE(ITS.timestamp), INTERVAL 3 MONTH); 
    -- to make sure shipped within 3 months of being sent to quarantine 