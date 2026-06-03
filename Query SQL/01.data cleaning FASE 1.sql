CREATE DATABASE IF NOT EXISTS automotive_analytics;
USE automotive_analytics;

DROP TABLE IF EXISTS vehicle_sales;

CREATE TABLE vehicle_sales (
    year INT,
    make VARCHAR(100),
    model VARCHAR(100),
    trim VARCHAR(100),
    body VARCHAR(100),
    transmission VARCHAR(50),
    vin VARCHAR(100), -- Rimosso temporaneamente come PRIMARY KEY per evitare blocchi se ci sono duplicati nel CSV sporco
    state VARCHAR(50),
    `condition` DECIMAL(3,1), -- Gestisce i numeri decimali es. 3.5 o 4.2
    odometer INT,
    color VARCHAR(100),
    interior VARCHAR(100),
    seller VARCHAR(255),
    mmr INT,
    sellingprice INT,
    saledate VARCHAR(255)
);

-- passaggio 2
SET GLOBAL local_infile = 1;
-- passaggio 3 con comando windows + r  e inserire path C:\ProgramData\MySQL\MySQL Server 8.0\Uploads e all'interno inserire file csv, e poi fare passaggio 4
-- passaggio 4
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/car_prices.csv'
INTO TABLE vehicle_sales
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(year, make, model, trim, body, transmission, vin, state, @vcondition, @vodometer, color, interior, seller, @vmmr, @vsellingprice, saledate)
SET 
`condition` = NULLIF(TRIM(@vcondition), ''),
odometer = NULLIF(TRIM(@vodometer), ''),
mmr = NULLIF(TRIM(@vmmr), ''),
sellingprice = NULLIF(TRIM(@vsellingprice), '');


--  PULIZIA E PREAPARAZIONE DATASET, FONDAMENTALE
use automotive_analytics;

-- conteggio dei valori null oppure con righe non compilate

SELECT 
    -- 1. CONTEGGIO TOTALE DEL DATASET
    COUNT(*) AS total_rows,
    -- 2. CONTROLLO COLONNE DI TESTO (Conta NULL, stringhe vuote, spazi nascosti e trattini)
    SUM(CASE WHEN make IS NULL OR TRIM(make) = '' OR make = '—' THEN 1 ELSE 0 END) AS missing_make,
    SUM(CASE WHEN model IS NULL OR TRIM(model) = '' OR model = '—' THEN 1 ELSE 0 END) AS missing_model,
    SUM(CASE WHEN trim IS NULL OR TRIM(trim) = '' OR trim = '—' THEN 1 ELSE 0 END) AS missing_trim,
    SUM(CASE WHEN body IS NULL OR TRIM(body) = '' OR body = '—' THEN 1 ELSE 0 END) AS missing_body,
    SUM(CASE WHEN transmission IS NULL OR TRIM(transmission) = '' OR transmission = '—' THEN 1 ELSE 0 END) AS missing_transmission,
    SUM(CASE WHEN vin IS NULL OR TRIM(vin) = '' THEN 1 ELSE 0 END) AS missing_vin,
    SUM(CASE WHEN state IS NULL OR TRIM(state) = '' THEN 1 ELSE 0 END) AS missing_state,
    SUM(CASE WHEN color IS NULL OR TRIM(color) = '' OR color = '—' THEN 1 ELSE 0 END) AS missing_color,
    SUM(CASE WHEN interior IS NULL OR TRIM(interior) = '' OR interior = '—' THEN 1 ELSE 0 END) AS missing_interior,
    SUM(CASE WHEN seller IS NULL OR TRIM(seller) = '' THEN 1 ELSE 0 END) AS missing_seller,
    SUM(CASE WHEN saledate IS NULL OR TRIM(saledate) = '' THEN 1 ELSE 0 END) AS missing_saledate,
    -- 3. CONTROLLO COLONNE NUMERICHE (Conta i NULL, gli zeri e ispeziona i limiti logici)
    SUM(CASE WHEN year IS NULL OR year = 0 THEN 1 ELSE 0 END) AS missing_year,
    MIN(year) AS min_year,
    MAX(year) AS max_year,

    SUM(CASE WHEN condizione IS NULL THEN 1 ELSE 0 END) AS missing_condition,
    MIN(condizione) AS min_condition,
    MAX(condizione) AS max_condition,

    SUM(CASE WHEN odometer IS NULL THEN 1 ELSE 0 END) AS missing_odometer,
    MIN(odometer) AS min_odometer,
    MAX(odometer) AS max_odometer,

    SUM(CASE WHEN mmr IS NULL OR mmr = 0 THEN 1 ELSE 0 END) AS missing_mmr,
    MIN(mmr) AS min_mmr,
    MAX(mmr) AS max_mmr,

    SUM(CASE WHEN sellingprice IS NULL OR sellingprice = 0 THEN 1 ELSE 0 END) AS missing_price,
    MIN(sellingprice) AS min_price,
    MAX(sellingprice) AS max_price

FROM vehicle_sales;


-- Statistiche valori all'interno delle tabelle, utili per vedere in alcuni casi i duplicati, valori manacanti, valori che non devono esserci all'interno di quella determianta tabella ecc
select make,count( make) as valore_trovato from vehicle_sales
group by 1 ;
select body,count(body) as valore_trovato from vehicle_sales
group by 1 ;
select condizione,count(condizione) as valore_trovato from vehicle_sales 
group by 1 order by valore_trovato ;
select color,count(color) as valore_trovato from vehicle_sales
group by 1 ;
select vin,count(vin) as valore_trovato from vehicle_sales
WHERE vin IS NOT NULL AND vin <> '' #escludiamo i nulli e i valori mancanti
group by 1 order by valore_trovato desc ;
select state,count(state) as valore_trovato from vehicle_sales
group by 1 ;
select interior,count( interior) as valore_trovato from vehicle_sales
group by 1 ;
select transmission,count( transmission) as valore_trovato from vehicle_sales
group by 1 ;
select condizione,count(condizione) as valore_trovato from vehicle_sales
group by 1 ;
select seller,count(seller) as valore_trovato from vehicle_sales group by 1 
order by valore_trovato desc ;

-- analisi per vin uguali ma che si ripetono piu volte, per andare a capire effettivamente la storia di questa auto.
SELECT 
    vin,
    make,
    model,
    COUNT(*) AS numero_tentativi_asta,
    MIN(odometer) AS km_alla_prima_asta,
    MAX(odometer) AS km_all_ultima_asta,
    (MAX(odometer) - MIN(odometer)) AS km_percorsi_tra_le_aste
FROM vehicle_sales
WHERE vin IN (
    'wbanv13588cz57827',
    'trusc28n241022003',
    '5uxfe43579l274932',
    'wp0ca2988xu629622',
    'wddgf56x78f009940',
    '1ft7w2btxdea03416',
    '1ftex1em5bfc39949',
    '1gyfk63887r125174'
)
GROUP BY vin, make, model;

-- Parte 3, PULIZIA ED ELIMINAZIONE DUPLICATI E SCELTA VIN CON ULTIMA RIGA DI MOVIMENTO 
create temporary table tab1 as (
with ranked_cars as
(select year,make,model,trim,body,
case
	when transmission is null or trim(transmission)= '' or transmission= '—' then 'Unknown' else transmission end as transmission,
vin,state,condizione,odometer,
case
	when color is null or trim(color)='' or color= '—' then 'Unknown' else color end as color,
case	
    when interior is null or trim(interior)= '' or interior= '—' then 'Unknown' else interior end as interior,
seller,mmr,sellingprice,REPLACE(saledate, '\r', '') AS saledate,
row_number()over(partition by vin order by odometer desc,sellingprice desc) as riga_numero from vehicle_sales
-- filtri
where 
 vin is not null
 and trim(vin) <>''
 and vin <>'automatic'
 and make is not null
 and trim(make) <>''
 and sellingprice > 100 )
 select year,make,model,trim,body,transmission,vin,state,condizione,odometer,color,interior,seller,mmr,sellingprice,saledate
 from ranked_cars
 where riga_numero=1);

-- andiamo a visualizzare la nostra nuova tabella temporanea con le pulize apportate
 select*from tab1;

-- andiamo a controllare nuovamente valori strani, null , duplicati ecc

select year,count(year) as valore_trovato from tab1 
group by 1 order by valore_trovato ;
select make,count(make) as valore_trovato from tab1 
group by 1 order by make;
select model,count(model) as valore_trovato from tab1 
group by 1 order by valore_trovato ;
select trim,count(trim) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select body,count(body) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select vin,count(vin) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select state,count(state) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select odometer,count(odometer) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select color,count(color) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select interior,count(interior) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select seller,count(seller) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select mmr,count(mmr) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select sellingprice,count(sellingprice) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select saledate,count(saledate) as valore_trovato from tab1
group by 1 order by valore_trovato ;
select transmission,count(transmission) as valore_trovato from tab1
group by 1 order by valore_trovato ;

-- RI ANDIAMO A CONTARE TUTTI GLI EVENTUALI VALORI MANCANTI E LE NUOVE STATISTICHE

SELECT 
    -- 1. CONTEGGIO TOTALE DEL DATASET
    COUNT(*) AS total_rows,
    -- 2. CONTROLLO COLONNE DI TESTO (Conta NULL, stringhe vuote, spazi nascosti e trattini)
    SUM(CASE WHEN make IS NULL OR TRIM(make) = '' OR make = '—' THEN 1 ELSE 0 END) AS missing_make,
    SUM(CASE WHEN model IS NULL OR TRIM(model) = '' OR model = '—' THEN 1 ELSE 0 END) AS missing_model,
    SUM(CASE WHEN trim IS NULL OR TRIM(trim) = '' OR trim = '—' THEN 1 ELSE 0 END) AS missing_trim,
    SUM(CASE WHEN body IS NULL OR TRIM(body) = '' OR body = '—' THEN 1 ELSE 0 END) AS missing_body,
    SUM(CASE WHEN transmission IS NULL OR TRIM(transmission) = '' OR transmission = '—' THEN 1 ELSE 0 END) AS missing_transmission,
    SUM(CASE WHEN vin IS NULL OR TRIM(vin) = '' THEN 1 ELSE 0 END) AS missing_vin,
    SUM(CASE WHEN state IS NULL OR TRIM(state) = '' THEN 1 ELSE 0 END) AS missing_state,
    SUM(CASE WHEN color IS NULL OR TRIM(color) = '' OR color = '—' THEN 1 ELSE 0 END) AS missing_color,
    SUM(CASE WHEN interior IS NULL OR TRIM(interior) = '' OR interior = '—' THEN 1 ELSE 0 END) AS missing_interior,
    SUM(CASE WHEN seller IS NULL OR TRIM(seller) = '' THEN 1 ELSE 0 END) AS missing_seller,
    SUM(CASE WHEN saledate IS NULL OR TRIM(saledate) = '' THEN 1 ELSE 0 END) AS missing_saledate,
    -- 3. CONTROLLO COLONNE NUMERICHE (Conta i NULL, gli zeri e ispeziona i limiti logici)
    SUM(CASE WHEN year IS NULL OR year = 0 THEN 1 ELSE 0 END) AS missing_year,
    MIN(year) AS min_year,
    MAX(year) AS max_year,

    SUM(CASE WHEN condizione IS NULL THEN 1 ELSE 0 END) AS missing_condition,
    MIN(condizione) AS min_condition,
    MAX(condizione) AS max_condition,

    SUM(CASE WHEN odometer IS NULL THEN 1 ELSE 0 END) AS missing_odometer,
    MIN(odometer) AS min_odometer,
    MAX(odometer) AS max_odometer,

    SUM(CASE WHEN mmr IS NULL OR mmr = 0 THEN 1 ELSE 0 END) AS missing_mmr,
    MIN(mmr) AS min_mmr,
    MAX(mmr) AS max_mmr,

    SUM(CASE WHEN sellingprice IS NULL OR sellingprice = 0 THEN 1 ELSE 0 END) AS missing_price,
    MIN(sellingprice) AS min_price,
    MAX(sellingprice) AS max_price

FROM tab1;

select *from tab1;
-- avendo fatto delle analisi su tutte la nuova tabelle creata, andremo a modificare e aggiornare ,essendo ancora piu precisi e dettagliati.

-- Nel campo trim compaiono ! e + in una bella quantità , modifichiamoli 

update tab1
set trim = 'Unknown'
where trim in('!', '+', '') OR trim IS NULL;
-- campo body vuoto, aggiorniamolo con unkonown
update tab1
set body= 'Unknown'
where trim(body) in ('') or body is null;
-- eliminazione dot da make
delete from tab1
where make = 'dot' ;
-- aggiornamento marche e unificazione 
update tab1
set make = case
when lower(make) in ('chev truck','chevrolet') then 'Chevrolet'
when lower(make) in ('dodge tk','dodge') then 'Dodge'
when lower(make) in ('ford tk','ford','ford truck') then 'Ford'
when lower(make) in ('gmc truck','gmg') then 'Gmc'
when lower(make) in ('hyundai tk','hyiundai') then 'Hyundai'
when lower(make) in ('land rover','landrover') then 'Land-Rover'
when lower(make) in ('mazda tk','mazda') then 'Mazda'
when lower(make) in ('mercedes','mercedes-b','mercedes-benz') then 'Mercedes-Benz'
when lower(make) in ('vw','volkswagen') then 'Volkswagen'
when make ='airstream' then 'Airstream'
when make ='Aston Martin' then 'Aston-Martin'
when make ='buick' then 'Buick'
when make ='FIAT' then 'Fiat'
when make ='HUMMER' then 'Hummer'
when make ='MINI' then 'Mini'
when make ='oldsmobile' then 'Oldsmobile'
when make ='pontiac' then 'Pontiac'
when make ='smart' then 'Smart'
else make
end ;

-- colonna state tutto in maiuscolo
update tab1
set state = upper(state) ;

-- ricontrolliamo tabella tab 1
select*From tab1;

-- andiamo eseguire il codice di prima sulle pulizie e andiamo a notare 98 righe vuote in model,  98*100/540162 fa 0,0018, che a livello di percentuale e' un numero bassissimo
#che sicuramente non va a influenzare le analisi, lo avremmo potuto tenere e cambiarlo in unknown, pero al momento delle analisi, avremmo ottenuto una marca x con un modello sconosciuto 
#e non ci avrebbe dato un risultato diretto e concreto. quindi scelgo la strada dell'eliminazione di queste 98 righe con il seguente codice
delete from tab1
WHERE model IS NULL OR TRIM(model) = '';

-- ora creo la famosa tabella pulita copiandola da questa temporanea

create table vehicle_sales_clean as
select * from tab1;
-- andiamo a visualizzarla
select * from vehicle_sales_clean ;

-- andiamo a modificare le date finali di vendita , (YYYY-MM-DD)
UPDATE vehicle_sales_clean
SET saledate = STR_TO_DATE(SUBSTRING(saledate, 5, 11), '%b %d %Y');

-- funzione str to date prende come sottostringa il valore 5 che sarebbe la prima lettera del mese fino alla lettera numero 11 dove si conclude con'l'anno
#le percentuali b d e y restituiscono due giorni del mese, due giorni del giorno e 4 cifre dell'anno

-- 2. Diciamo a MySQL che questa colonna ora è ufficialmente una Data (e non più un testo)
ALTER TABLE vehicle_sales_clean
MODIFY COLUMN saledate DATE;

-- andiamo a visualizzar la nuova tabella con le modifiche apportate 
select*from vehicle_sales_clean;

select*from vehicle_sales_clean where odometer >500000 
order by sellingprice asc ;



