
<p align="center"> 
<i> Progetto - Vehicle Sales Data </i> <br> <sub>
<img width="50" height="50" alt="image" src="https://github.com/user-attachments/assets/94d594d8-788e-40fd-86b4-22d2ac8145dd" /> 
<img width="50" height="50" alt="image" <img width="30 height="30" alt="image" src="https://github.com/user-attachments/assets/5d6ca38c-dbbd-41d9-9cb3-49f644f50c7b" />

# Contesto e Obiettivo
Il mercato automotive è caratterizzato da un'elevata competitività e da volumi massicci di transazioni quotidiane. In questo scenario, i decisori aziendalimsi trovano spesso a dover navigare all'interno di database enormi e disgiunti, rendendo complesso isolare i trend reali di profittabilità, monitorare la distribuzione geografica delle vendite e identificare tempestivamente le combinazioni ottimali tra volumi di stock e prezzi di listino.

L'obiettivo di questo progetto è trasformare un set di dati grezzo e non ottimizzato in una piattaforma di Sales Intelligence scalabile, efficiente e impattante visimamente.

# Struttura del Progetto
Il seguente progetto e' basato su un dataset unico composto da 16 colonne dove ognuna di esse contiente elementi contraddistinti per ogni tipo di veicolo. In particolare, troviamoa dettagli quali anno, marca, modello, allestimento, tipo di carrozzeria, tipo di trasmissione, VIN (numero di identificazione del veicolo), stato di immatricolazione, valutazione delle condizioni, lettura del contachilometri, colori esterni e interni, informazioni sul venditore, valori del Manheim Market Report (MMR), prezzi di vendita e date di vendita.

Link al al DATASET 👉 (https://www.kaggle.com/datasets/syedanwarafridi/vehicle-sales-data)

# Fasi del progetto
## 🗄️ Fase 1: Data Cleaning e Strutturazione (MySQL)
Il progetto è partito con l'importazione dei dati grezzi all'interno di un database MySQL. Il file è stato implementato tramite il seguente codice per garantire performance e accuratezza dei dati:
```sql
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
```
**Data Cleaning**: Identificazione e gestione dei valori mancanti, fase cruciale per garantire l'affidabilità delle analisi successive. Il codice implementato rileva sistematicamente valori NULL, stringhe vuote, spazi nascosti e trattini. In parallelo, lo studio dei valori minimi e massimi per ciascuna colonna ha permesso di individuare tempestivamente anomalie e outlier, guidando le decisioni strategiche sul trattamento futuro dei dati. ( codice riutilizzabile anche in altri contesti, importante e' cambiare i nomi delle varie colonne)

```sql
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

```

**Decisione sui VIN** : Qui c'è stata un'importante analisi strutturale. Il VIN (o numero di telaio) è univoco per ogni auto, quindi all'interno di questo dataset ho ritrovato molti VIN che si presentavano più di una volta, alcuni non erano nemmeno citati e altri avevano errori, tipo la scritta "automatic". Qui ho dovuto capire perché questi VIN si andavano a ripetere per più volte e, dopo un'attenta analisi, sono riuscito a ricostruire la storia di alcune determinate auto dove il VIN appunto si ripeteva. Nel risultato del seguente codice si va a mostrare la storia di ogni singola auto e i km percorsi da un posto a un altro prima di essere venduta. In questo modo ho deciso di prendere solo l'ultima riga, ovvero quella della vendita finale, poiché è quella che ci serve per continuare l'analisi. Facendo così, ho ottenuto ogni VIN singolo per auto e non ho più duplicati o valori nulli. I VIN utilizzati sono alcuni di quelli che si ripetevano.

```
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


| vin | make | model | numero_tentativi_asta | km_alla_prima_asta | km_all_ultima_asta | km_percorsi_tra_le_aste |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| 1ftex1em5bfc39949 | Ford | F-150 | 3 | 91626 | 91632 | 6 |
| 5uxfe43579l274932 | BMW | X5 | 4 | 80986 | 81230 | 244 |
| wp0ca2988xu629622 | Porsche | Boxster | 4 | 82131 | 82176 | 45 |
| wddgf56x78f009940 | Mercedes-Benz | C-Class | 4 | 89385 | 90066 | 681 |
| 1ft7w2btxdea03416 | Ford | F-250 Super Duty | 3 | 33173 | 33497 | 324 |
| wbanv13588cz57827 | BMW | 5 Series | 5 | 122065 | 122278 | 213 |
| 1gyfk63887r125174 | Cadillac | Escalade | 3 | 111681 | 111728 | 47 |
| trusc28n241022003 | Audi | TT | 4 | 91439 | 91854 | 415 |

```

**Pulizia ed eliminazione valori duplicati**:In questa parte vado a pulire ed eliminare all'interno del dataset tutti i valori duplicati e quelli che contengono valori nulli, stringhe vuote o caratteri speciali. Creo una tabella temporanea per salvare all'interno di essa questa prima parte di dataset pulito. Prendo in considerazione solo le auto vendute con un prezzo maggiore di 100 ai fini dell'analisi futura. Una volta completata l'operazione, ricontrollo nuovamente la presenza di eventuali valori nulli, duplicati o la presenza di altri caratteri speciali.

```sql
--  PULIZIA ED ELIMINAZIONE DUPLICATI E SCELTA VIN CON ULTIMA RIGA DI MOVIMENTO 
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

```

```










