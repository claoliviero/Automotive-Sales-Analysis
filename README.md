<p align="center"> 
<i><b>Progetto - Vehicle Sales Data</b></i> <br>
<img width="50" height="50" alt="image" src="https://github.com/user-attachments/assets/94d594d8-788e-40fd-86b4-22d2ac8145dd" /> 
<img width="50" height="50" alt="image" src="https://github.com/user-attachments/assets/5d6ca38c-dbbd-41d9-9cb3-49f644f50c7b" />
</p>


# Contesto e Obiettivo
Il mercato automotive è caratterizzato da un'elevata competitività e da volumi massicci di transazioni quotidiane. In questo scenario, le decisioni aziendali trovano spesso a dover navigare all'interno di database enormi e disgiunti, rendendo complesso isolare i trend reali di profittabilità, monitorare la distribuzione geografica delle vendite e identificare tempestivamente le combinazioni ottimali tra volumi di stock e prezzi di listino.

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

```sql
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
**Nuova pulizia e sostituzione valori**:Andando quindi a controllare nuovamente la nuova tabella temporanea, sono saltate fuori alcune "anomalie" da sistemare e valori da correggere. Nel campo trim sono presenti valori come !, +, spazi vuoti e virgolette ("), quindi li andremo a cambiare con "Unknown". Per il campo make (marchio) è presente un valore del tutto anomalo, ovvero dot, e la maggior parte dei marchi sono scritti con la lettera minuscola; quindi modifico questi valori con la lettera maiuscola, e questo per unificare tutto, cosa importante per il case-sensitive. Ci sono anche marche con scritto ad esempio gmc truck, chev tk, ford tk ecc., e queste sono tutte da cambiare. La colonna state è tutta in minuscolo e la vado a cambiare tutta in maiuscolo, come è giusto che sia per gli stati, quindi ad esempio ca diventa CA, ecc.

```sql
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
select*From tab1;```
```
**Eliminazione 98 valori nulli con motivo di questa scelta** :  Appena controllata la nuova tabella temporanea attraverso le query dei conteggi per andare a rivedere nuovamente valori anomali o vuoti, osservo la presenza di 98 valori nulli nel campo trim. 98 valori nulli su 540163 rappresentano una percentuale dello 0,018%, un valore estremamente insignificante anche ai fini dell'analisi finale. Quindi li vado ad eliminare e creo una nuova tabella , non piu temporanea con tutti valori nuovi e puliti.


```sql

-- andiamo eseguire il codice di prima sulle pulizie e andiamo a notare 98 righe vuote in model,  98*100/540162 fa 0,0018, che a livello di percentuale e' un numero bassissimo
#che sicuramente non va a influenzare le analisi, lo avremmo potuto tenere e cambiarlo in unknown, pero al momento delle analisi, avremmo ottenuto una marca x con un modello sconosciuto 
#e non ci avrebbe dato un risultato diretto e concreto. quindi scelgo la strada dell'eliminazione di queste 98 righe con il seguente codice
delete from tab1
WHERE model IS NULL OR TRIM(model) = '';

-- creo la tabella pulita copiandola da questa temporanea

create table vehicle_sales_clean as
select * from tab1;
-- andiamo a visualizzarla
select * from vehicle_sales_clean ;
```

**Modifica date di vendita con formato (YYYY-MM-DD) piu' anottazione finale extra**: Nella colonna saledate il formato dei dati è una stringa contenente i seguenti valori: <br>
Esempio: saledate -----> 'Tue Dec 16 2014 12:30:00 GMT-0800 (PST)\r'<br>
Questo formato può sembrare anche utile e molto dettagliato, data la presenza del giorno della settimana in cui è stata venduta l'auto e del relativo orario, ma ai fini delle analisi future questo dato non è rilevante. Ciò che è veramente importante e utile è che questa stringa diventi un vero campo data, contenente anno, mese e giorno della vendita. Questo passaggio è fondamentale per poter calcolare insight sulle date. Ovviamente, quel valore finale \r va eliminato.

```sql
-- andiamo a modificare le date finali di vendita , (YYYY-MM-DD)
UPDATE vehicle_sales_clean
SET saledate = STR_TO_DATE(SUBSTRING(saledate, 5, 11), '%b %d %Y');

-- funzione str to date prende come sottostringa il valore 5 che sarebbe la prima lettera del mese fino alla lettera numero 11 dove si conclude con'l'anno
#le percentuali b d e y restituiscono due giorni del mese, due giorni del giorno e 4 cifre dell'anno

-- 2. Diciamo a MySQL che questa colonna ora è ufficialmente una Data (e non più un testo)
ALTER TABLE vehicle_sales_clean
MODIFY COLUMN saledate DATE;

-- andiamo a visualizzare la nuova tabella con le modifiche apportate 
select*from vehicle_sales_clean;
```

***Extra finale*** : La colonna odometer presenta auto con 999.999 chilometri. Questo potrebbe essere dovuto a un errore durante l'inserimento dei dati, a contachilometri non efficienti (e quindi rotti), oppure a condizioni dell'auto così pessime da non permetterne il rilevamento. Infatti, ricordiamoci che abbiamo una colonna "condizione" che usa valori che vanno da 1 a 50.<br>

Punteggi bassi (vicini a 1): Auto con gravi danni, chilometraggi altissimi o non marcianti.

Punteggi alti (vicini a 49/50): Auto in condizioni da showroom, praticamente perfette.

```sql
select*from vehicle_sales_clean where odometer >500000 
order by sellingprice asc ;

| year | make | model | trim | body | transmission | vin | state | condizione | odometer | color | interior | seller | mmr | sellingprice | saledate |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: | :---: | :--- | :--- | :--- | :---: | :---: | :---: |
| 2008 | Nissan | Rogue | S | SUV | Unknown | jn8as58t48w002423 | MD | 1.0 | 999999 | Unknown | Unknown | wells fargo dealer services | 3650 | 275 | 2014-12-30 |
| 2010 | Chevrolet | Cobalt | LT | Sedan | automatic | 1g1af5f55a7180158 | NY | 1.0 | 999999 | silver | black | santander consumer | 2850 | 275 | 2014-12-31 |
| 1997 | Mazda | Protege | LX | sedan | automatic | jm1bc141xv0109453 | FL | 1.0 | 999999 | blue | beige | coggin toyota at the avenues | 200 | 325 | 2015-06-04 |
| 1998 | Lexus | ES 300 | Base | Sedan | automatic | jt8bf28g4w5037146 | CA | 2.0 | 999999 | gray | beige | 800 loan mart | 650 | 350 | 2015-02-17 |

```

**Data Analysis (EDA) & Business Queries** : Prima di creare le viste finali per Tableau, ho strutturato l'analisi in vari Task per fare un sanity check dei dati, scovare anomalie e iniziare a estrarre i primi veri insight di business.

*Task 1.1: La Caccia agli Outliers (Sanity Check)*: <br>
Per prima cosa ho verificato la qualità dei dati. Ho cercato anomalie evidenti nel chilometraggio (auto sotto le 50 miglia o sopra le 300.000) e nei prezzi di vendita assurdi (sotto i 500$ o sopra i 150.000$).


```sql

select year,make,model,odometer,mmr from vehicle_sales_clean 
where odometer < 50 or odometer >300000 
order by odometer asc ;

#Scrivo un'altra query per trovare i prezzi di vendita assurdi (es. sellingprice sotto i 500$ o sopra i 100.000$).
select year,make,model,odometer,mmr,sellingprice from vehicle_sales_clean
where sellingprice <500 or sellingprice >150000
order by sellingprice asc ,odometer asc ;

Select year,
sum(case when odometer = 1 then 1 else 0 end) as conteggio_1km,
sum(case when odometer > 900000  then 1 else 0 end) as conteggio_999999km
from vehicle_sales_clean
group by 1 order by year;
-- totale 1154 auto che hanno 1 km e piu di 900000 km su un totale di 540064, ovvero il 2%

```

*Task 1.2: Segmentazione del Mercato (Fasce di Prezzo)*: <br>
Ho diviso le auto in tre macro-fasce usando la logica del CASE WHEN: Low Cost (< 10k$), Mid Range (tra 10k$ e 39k$) e Premium (sopra i 40k$).

```sql

select year,make,model,condizione,sellingprice,
case
	when sellingprice < 10000 then 'Low cost'
    when sellingprice between 10000 and 39999 then 'Mid range'
    else 'Premium'
end as price_ranges 
from vehicle_sales_clean
order by price_ranges desc ,sellingprice desc ;

```

*Task 1.3: Volumi e Valori per Brand*: <br>
Quali sono i marchi che muovono più soldi e più veicoli? Ho raggruppato i dati per marca, calcolato le auto vendute, il prezzo medio (arrotondato) e il fatturato totale, filtrando solo i brand con più di 1.000 vendite.


```sql

select make,count(*) as cars_sold, round(avg(sellingprice),0) as avg_sellingprince,sum(sellingprice) as total_sales_prices
from vehicle_sales_clean
group by 1
having cars_sold > 1000 
order by total_sales_prices desc;

```

**LIVELLO 2: Analisi di Performance e Geografica** :

*Task 2.1:(MMR vs Selling Price)*: <br>
L'MMR (Manheim Market Report) indica il valore stimato dell'auto. Chi siamo riusciti a vendere sopra il valore di mercato e chi abbiamo dovuto svendere?


```sql

select make,count(*) as cars_sold,(avg(sellingprice-mmr)) as avg_margin
from vehicle_sales_clean
group by 1
having cars_sold >500
order by avg_margin desc ;

```

*Task 2.2: Le Roccaforti (Analisi Geografica)*: <br>
Mappiamo le performance degli hub commerciali: ecco i top 5 Stati per fatturato totale, con tanto di condizione media delle auto vendute.

```sql
select state,count(*) as number_of_sales,sum(sellingprice) as total_turnover,round(avg(condizione),1) as avg_condition
from vehicle_sales_clean
group by 1
order by total_turnover desc 
limit 5 ;

```

*Task 2.3: Focus sui Top Seller (Il caso Ford)*: <br>
Visto che dal Task 1.3 è emerso che Ford è il nostro brand leader assoluto con oltre 1.3 miliardi di fatturato, ho isolato la top 10 dei modelli Ford più venduti in azienda usando una CTE.

```sql

with general_data as
(select make,count(*) as cars_sold, model, round(avg(sellingprice),0) as avg_sellingprice,sum(sellingprice) as total_sales_prices
from vehicle_sales_clean
group by make,model
having cars_sold > 1000)
select make,model,cars_sold,avg_sellingprice,total_sales_prices from general_data
where make = 'Ford'
order by cars_sold desc 
limit 10 ;

```

**LIVELLO 3: Funzioni Finestra e Trend Temporali:**

*Task 3.1: La Top 3 Assoluta per Brand (Window Functions)* <br>
Andiamo a scoprire i primi 3 modelli più venduti per OGNI marca. Un semplice LIMIT 3 qui sarebbe fallito. Ho risolto da professionista usando le CTE e la funzione finestra ROW_NUMBER().

```sql

with general_date as (
  select make,model,count(*) as cars_sold,sum(count(*)) over(partition by make) as total_brand_sales
  from vehicle_sales_clean 
  group by 1, 2
),
position as (
  select make,model,cars_sold,total_brand_sales,row_number() over(partition by make order by cars_sold desc) as rank_position 
  from general_date)
select make, model, cars_sold, rank_position 
from position
where total_brand_sales >= 1000 and rank_position <= 3;

```

*Task 3.2: Il Trend Mese-su-Mese (Time Series & LAG)* <br>
Per analizzare l'andamento temporale delle vendite, ho estratto anno e mese e ho sfruttato la funzione LAG() per confrontare il mese attuale con quello precedente, calcolando la variazione percentuale.

```sql

with general_date as
(select make,count(*) as cars_sold,year(saledate) as year_sales,monthname(saledate) as month_name_sales,month(saledate) as month_number_sales from vehicle_sales_clean
group by 1,3,4,5),
general_last_month as
(select make,year_sales,month_number_sales,month_name_sales,cars_sold,lag(cars_sold,1)over(partition by make order by year_sales,month_number_sales) as sales_last_month from general_date)
select make,year_sales,month_number_sales,month_name_sales,cars_sold,sales_last_month,
round(((cars_sold - sales_last_month) / sales_last_month) * 100, 2) AS percentage_change
from general_last_month;

```

*Task 3.3: L'impatto dei Chilometri sul Deprezzamento* <br>
Volevo dimostrare matematicamente come il chilometraggio distrugge il valore delle auto. Ho diviso l'odometro in 4 fasce e calcolato il prezzo medio di vendita per ciascuna.

 ```sql

select case 
	when odometer <=50000 then '1_Low_km'
    when odometer <=100000 then '2_Medium_km'
    when odometer <=150000 then '3_High_km'
    else '4_Very_high_km'
end as 'km_bands' ,
round(avg(sellingprice),2) as avg_selling_price from vehicle_sales_clean
group by km_bands
order by km_bands;

 ```

**LIVELLO 4 & 5: Analisi Avanzate di Business:**

*Task 4.1: Le Quote di Mercato (Market Share % in California)* <br>
Quanto "pesa" ogni singolo brand sul totale delle auto vendute nello stato della California (CA)?

 ```sql

with total_california as
(select state,count(*) as cars_sold from vehicle_sales_clean where state = 'CA'),
california_make as
(select state,make,count(*) as cars_sold_california from vehicle_sales_clean
where state ='CA'
group by 1,2),
percentage as
(select cm.make,round((cm.cars_sold_california/t.cars_sold)*100,2) as percentage_by_state from total_california t join california_make cm 
on t.state=cm.state)
select make,percentage_by_state,row_number()over(order by percentage_by_state desc) as row_position_for_state from percentage
limit 10 ;

```

*Task 4.2: La Media Mobile a 3 Mesi (Rolling Average)* <br>
I grafici temporali a volte sono troppo altalenanti ("a zig-zag"). Ho implementato una media mobile a 3 mesi utilizzando la clausola ROWS BETWEEN 2 PRECEDING AND CURRENT ROW per smussare le fluttuazioni e mostrare il trend reale.

```sql

with generale as
(select year(saledate) as year_sales,monthname(saledate) as month_name_sales,month(saledate) as month_number_sales,count(*) as cars_sold from vehicle_sales_clean
group by 1,2,3)
select year_sales,month_name_sales,month_number_sales,cars_sold,round(avg(cars_sold)over(order by year_sales asc,month_number_sales asc rows between 2 preceding and current row),0)
as avg_mobile_3Month
from generale ;

```

*Task 4.3: La Caccia all'Affare* <br>
Ho scritto una query per identificare le auto "sottovalutate" sul mercato, utili per operazioni di flipping: ottime condizioni ($\ge 45$), basso chilometraggio ($< 40.000\text{ km}$) e uno sconto sul valore stimato superiore al 20%.

```sql

with discount as
(select vin,make,model,mmr,sellingprice,odometer,condizione,(mmr - sellingprice) AS net_profit_potential,round(((mmr - sellingprice) / mmr) * 100, 2) AS discount_pct from vehicle_sales_clean
having(sellingprice < mmr*0.8))
select vin,make,model,mmr,sellingprice,net_profit_potential,discount_pct,condizione from discount
where condizione>= 45.0 and odometer <40000 
order by condizione desc ;

```

*Task 5: Analisi di pareto (Fatturato Cumulativo)* <br>
Per capire l'accentramento del fatturato, ho calcolato il running total del profitto dei marchi associando la percentuale cumulata riga dopo riga. Questa logica è stata la base per creare il diagramma di Pareto su Tableau.

```sql

with general_profit as
(select make,sum(sellingprice) as total_profit from vehicle_sales_clean group by 1 ),
general_running as
(select make,total_profit,sum(total_profit)over(order by total_profit desc) as running_total, SUM(total_profit) OVER () AS absolute_total from general_profit)
select make,total_profit,running_total,round((running_total/absolute_total)*100,2) as cumulative_percentage from general_running;

```

**LIVELLO 6: Segmentazione Avanzata tramite Quartili (NTILE)** <br>
Nell'ultimo step ho utilizzato la funzione statistica NTILE(4) per suddividere le auto del brand Ford (e successivamente l'intero dataset per ogni marca) in 4 gruppi uguali basati interamente sul chilometraggio, calcolandone i relativi range e prezzi medi di vendita.


```sql

-- Approccio 1: Analisi aggregata sui modelli Ford
with generale as
(select make,model,count(*) as total_cars,sum(odometer) as total_odometer,avg(sellingprice) as avg_sellingprice from vehicle_sales_clean 
where make='ford' 
group by 1,2),
quartili as
(select make,model,total_cars,total_odometer,ntile(4)over(order by total_odometer asc)as quartiles_km, avg_sellingprice from generale)
select quartiles_km,count(model)as total_models,sum(total_cars) as tot_cars,min(total_odometer)as min_km,max(total_odometer)as max_km, 
round(avg(avg_sellingprice),2)as avg_sellingprice from quartili 
group by 1;

-- Approccio 2: Analisi puntuale sui singoli veicoli Ford
with quartili_singoli as 
(select make,model,odometer,sellingprice,
ntile(4) over(order by odometer asc) as quartile_km from vehicle_sales_clean
where make = 'ford' 
    and odometer > 0)
select quartile_km,count(*) as tot_cars,min(odometer) as min_singolo_km,max(odometer) as max_singolo_km,round(avg(sellingprice), 2) as prezzo_medio_vendita
from quartili_singoli
group by 1
order by 1;

-- Approccio 3: Estensione universale su tutte le auto del dataset tramite PARTITION BY
with quartili_singoli as 
(select make,model,odometer,sellingprice,
ntile(4) over(partition by make order by odometer asc) as quartile_km from vehicle_sales_clean
    where odometer is not null
    and odometer > 0)
select quartile_km,count(*) as tot_cars,min(odometer) as min_singolo_km,max(odometer) as max_singolo_km,round(avg(sellingprice), 2) as prezzo_medio_vendita
from quartili_singoli
group by 1
order by 1;

```

## 🗄️ Fase 2: Visual Analytics & Dashboarding (MySQL + Tableau)

Una volta sistemati i dati con SQL, ho creato delle viste, che andavano a fare riferimento alle query precedenti per essere ri-utilizzate in qualsiasi momento senza scrivere nuovamente il codice e possibilmente adattarle a nuovi contesti. Una volta fatto ciò, ho collegato tutto a Tableau per creare una dashboard interattiva. Ho cercato di progettarla pensando a chi deve prendere decisioni in azienda.

```sql

-- ---------------------------------------CREAZIONE VISTE PER TABLEAU E RI-UTILIZZO CODICE PER ALTRE ANALISI DETTAGLIATE SU MY SQL------------------------------------------------
-- VISTA  1 per ogni stato e la sua percentuale per ogni marca e auto venduta, il suo impatto.-- ---------------------------------------
CREATE VIEW vw_market_share_state AS
select state,make,count(*) as cars_sold,ROUND((COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY state)) * 100, 2) 
as state_market_share_pct
from vehicle_sales_clean
where state is not null and make is not null
group by state, make;

SELECT*from vw_market_share_state;

---------------------------------------------------------- Vista  2 media mobile di auto vendute per mese e anno ---------------------------------------------------------------------
CREATE VIEW vw_sales_trend_rolling as
(with generale as
(select year(saledate) as year_sales,monthname(saledate) as month_name_sales,month(saledate) as month_number_sales,count(*) as cars_sold from vehicle_sales_clean
group by 1,2,3)
select year_sales,month_name_sales,month_number_sales,cars_sold,round(avg(cars_sold)over(order by year_sales asc,month_number_sales asc rows between 2 preceding and current row),0)
as avg_mobile_3Month
from generale);

SELECT*from vw_sales_trend_rolling;


-- ------------------------------------- Vista 3 , contiene tutte le auto con i relativi vin vendute  a un prezzo di mercato inferiore---------------------------------------------------------

CREATE VIEW vw_arbitrage_opportunities AS
(with discount as
(select vin,make,model,mmr,sellingprice,odometer,condizione,(mmr - sellingprice) AS net_profit_potential,round(((mmr - sellingprice) / mmr) * 100, 2) AS discount_pct from vehicle_sales_clean
having(sellingprice < mmr*0.8))
select vin,make,model,mmr,sellingprice,net_profit_potential,discount_pct,condizione from discount
where condizione>= 45.0 and odometer <40000 
order by condizione desc);

SELECT*from vw_arbitrage_opportunities ;

------------------------------------- Vista 4, pareto revenue, query che mostra la regola di pareto, ovvero l'80 % dei guadagni viene dal 20% dei prodotti. La tabbella afferma cio -----------------------------
use automotive_analytics;
CREATE VIEW vw_pareto_revenue AS
(with general_profit as
(select make,sum(sellingprice) as total_profit from vehicle_sales_clean group by 1 ),
general_running as
(select make,total_profit,sum(total_profit)over(order by total_profit desc) as running_total, sum(total_profit) over () AS absolute_total from general_profit)
select make,total_profit,running_total,round((running_total/absolute_total)*100,2) as cumulative_percentage from general_running);

SELECT*from vw_pareto_revenue ;

-------------------------------- Vista 5  abbiamo 4 quartili divisi per chilometri percorsi di ogni auto, con il suo min e max di chilometri per ogni quartile e il relativo prezzo di vendita ----------

CREATE VIEW vw_depreciation_quartiles AS
(with quartili_singoli as 
(select make,model,odometer,sellingprice,
ntile(4) over(partition by make order by odometer asc) as quartile_km from vehicle_sales_clean
    where odometer is not null
    and odometer > 0)
select quartile_km,count(*) as tot_cars,min(odometer) as min_singolo_km,max(odometer) as max_singolo_km,round(avg(sellingprice), 2) as prezzo_medio_vendita
from quartili_singoli
group by 1
order by 1);

SELECT*from vw_depreciation_quartiles ;


-- ---------------------------------------------------------------------VIsta 6, identica alla 5 ma aggiungendo le varie marche ( make) -------------------------------------------------
CREATE VIEW vw_depreciation_quartiles_make AS
(with quartili_singoli as 
(select make,model,odometer,sellingprice,
ntile(4) over(partition by make order by odometer asc) as quartile_km from vehicle_sales_clean
    where odometer is not null
    and odometer > 0)
select quartile_km,make,count(*) as tot_cars,min(odometer) as min_singolo_km,max(odometer) as max_singolo_km,round(avg(sellingprice), 2) as prezzo_medio_vendita
from quartili_singoli
group by 1,2
order by 1);

SELECT*from vw_depreciation_quartiles_make ;


-- ----------------------------------------------------VISTA 7 , UGUALE al market share state ma senza make ----------------------------

CREATE VIEW vw_market_share_for_state AS
(with generale as
(select state, count(*) as cars_sold, round(avg(sellingprice),2) as avg_selling_price
from vehicle_sales_clean
group by 1)
select state,cars_sold,avg_selling_price,round((cars_sold/ SUM(SUM(cars_sold)) OVER())* 100,2) AS state_market_share_pct  from generale 
group by 1);

select*from vw_market_share_for_state ;





----------------------------------------------- vista 8-  simile alla 6 ma con aggiunta di state, questo utile per le fasi successive su tableau----------------------

CREATE VIEW vw_depreciation_quartiles_withMAKE_STATE as
(with quartili_singoli as 
(select state,make,model,odometer,sellingprice,
ntile(4) over(partition by make order by odometer asc) as quartile_km from vehicle_sales_clean
    where odometer is not null
    and odometer > 0)
select state,quartile_km,make,count(*) as tot_cars,min(odometer) as min_singolo_km,max(odometer) as max_singolo_km,round(avg(sellingprice), 2) as prezzo_medio_vendita
from quartili_singoli
group by 1,2,3
order by 1);

select *from vw_depreciation_quartiles_withMAKE_STATE;

```

# Dashboard Development , passaggio a Tableau

Una volta finito tutto  su MySQL, ho spostato il progetto su **Tableau Desktop** per trasformare i dati in un'interfaccia interattiva e parlante. Di seguito trovi la cronostoria passo-passo di come ho strutturato la pipeline di visualizzazione.

---

*Passaggi e Pipeline di Sviluppo*

#### 1. Connessione ai Dati e Ottimizzazione del Caricamento
* **Azione:** Ho importato le viste SQL aggregate precedentemente create su MySQL.
* **Scelta Tecnica:** Invece di lavorare con una connessione *Live* (che avrebbe rallentato l'interfaccia a causa delle oltre 539k righe), ho generato un **Estratto di dati (.hyper)**. Questo ha azzerato la latenza di calcolo, garantendo filtri istantanei nella dashboard finale.

#### 2. Definizione del Layout e Strategia UX/UI (Design System)
* **Azione:** Ho impostato la struttura grafica dell'interfaccia optando per un **Dark Canvas** (sfondo antracite scuro).

#### 3. Sviluppo delle KPI Cards Principali (Executive Overview)
* **Azione:** Ho posizionato nella parte alta della dashboard i tre indicatori chiave di prestazione (KPI) aziendali:
    * **Volumi Totali:** Conteggio esatto delle transazioni attive (**539.988**).
    * **Prezzo Medio Ponderato Reale:** Calcolato tramite campi calcolati per superare le distorsioni della media semplice (**13.691 €**).
 
#### 4. Costruzione del Core Analitico (Mappa & Scatter Plot)
* **Mappa Geografica Interattiva:** Ho inserito una mappa del mercato nordamericano per visualizzare la distribuzione geografica delle vendite. La mappa è stata configurata non solo come grafico passivo, ma come un vero e proprio "pannello di comando" (Filtro di origine globale).
* **Scatter Plot Prezzo/Volume:** Ho tracciato la relazione tra volumi venduti e prezzo medio per brand. Questo mi ha permesso di isolare visivamente i cluster di mercato: il quadrante "alto volume/basso prezzo" (dove dominano Ford e Chevrolet) e le nicchie "alto valore/basso volume".

#### 5. Implementazione del Diagramma di Pareto (Analisi 80/20) e Viz-in-Tooltip
* **Azione:** Ho strutturato un grafico a doppio asse (barre per i volumi e linea continua per la percentuale cumulata) per applicare la legge di Pareto.

#### 6. Integrazione di Estensioni Avanzate (Il Donut Chart)
* **Azione:** Per variare la visualizzazione ed evitare i classici grafici a barre, ho implementato l'estensione nativa vizzu/LaDataViz per generare un **Donut Chart** dinamico focalizzato sulle quote di mercato degli Stati.

#### 6. Integrazione di Estensioni Avanzate ( Grafico ad area polare (Polar Area))
* **Azione:**  Anche qui per variare la visualizzazione , ho implementato l'estensione nativa per generare un **Polar area** dinamico focalizzato sulle auto vendute da ogni Stato e il relativo prezzo medio di vendita.

#### 7. Debugging delle Estensioni Web e Pubblicazione Finale
* **Deployment:** Ho pubblicato la cartella di lavoro su **Tableau Public**, configurando correttamente i permessi di visualizzazione (mostrando il progetto come una *Storia* logica) e abilitando il download del file `.twbx`. La dashboard e' dinamica, se filtri per uno Stato o clicchi su un gruppo specifico di auto, l'intera pagina si aggiorna da sola mostrandoti solo quello che ti serve in quel momento. Le storie invece vanno ad evidenziare determinati pattern di questo progetto e per ognuna di esse ho allegato un analisi dettagliata.


##### - Sono presenti immagini e visualizzazioni relative al progetto nella cartella Screenshots.


# 💡 Valore Aziendale e Considerazioni Finali (Business Value)

Questo progetto non è stato solo un esercizio di scrittura di query o di design di grafici. L'obiettivo fin dall'inizio era prendere un dataset di oltre 540.000 transazioni nel mercato dei veicoli e trasformarlo in un **asset strategico aziendale**. I dati , se presi e messi in fila nel modo giusto, raccontano una storia e aiutano a prendere importanti decisioni. <br>

Mettendo in fila i marchi, il fatturato ovviamente è diverso per ogni brand e soprattutto non è diviso in modo equo. **Ford** da sola muove una montagna di soldi (oltre *1.3 miliardi di dollari*). Sapere esattamente quali sono i 10 modelli Ford che tirano di più l'azienda (trovati con le mie CTE) permette a un concessionario di fare scorte mirate.**I chilometri distruggono il valore**: usando la funzione *NTILE(4)*, ho "affettato" il dataset in quattro gruppi identici basati sui chilometri. Guardando i prezzi medi di ogni gruppo, si vede a colpo d'occhio la curva di svalutazione. Questo per un venditore è un'informazione importantissima, appunto per capire quando e a quanti chilometri poter vendere o acquistare un'auto. Molto utile anche il grafico temporale dove ho usato la *Media Mobile a 3 mesi (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)*, fondamentale per vedere trend reali, stagionali e puliti.**Il Task 4.3** cerca invece auto in condizioni eccellenti, con pochi chilometri ma svendute a un prezzo inferiore di almeno il *20%* rispetto al loro valore reale di mercato *(MMR)*. Si può usare questa logica per intercettare all'istante le auto sottoprezzate alle aste, comprarle e rivenderle subito facendo margine.<br>

Questo progetto mi è servito tantissimo per ribadire nuovamente l'importanza dell'intera pipeline della *data analysis*. Prendere dati grezzi e sporchi, pulirli e organizzarli *(MySQL)*, porsi le domande giuste e scrivere query (CTE, WINDOW FUNCTIONS) per trovare dove si nascondono anomalie o insight importanti. Costruire una dashboard interattiva su *Tableau* che sia utile per prendere decisioni e infine, ma non per importanza, tradurre i numeri in azioni pratiche, fondamentali per il business.

# 🧠 Tecnologie e Competenze Utilizzate

### 🗄️ Ingegnerizzazione e Analisi del Dato (Backend)
* **MySQL:** Database management.
* **Skills SQL:** Common Table Expressions (CTE), Funzioni Finestra (`ROW_NUMBER()`, `LAG()`, `NTILE()`), calcoli condizionali (`CASE WHEN`) e la creazione di viste (Views) ottimizzate.

### 📊 Visual Analytics & Business Intelligence (Frontend)
* **Tableau (Desktop & Public):** Lo strumento che ha trasformato i numeri in un'interfaccia parlante.
* **Skills Tableau:** Scatter plot per i cluster, Diagramma di Pareto , Parametri e Filtri dinamici, Campi Calcolati , Donut Chart & Polar area dinamici.

### 🌐 Deployment & Web Hosting
* **''GitHub Pages:** Sfruttando GitHub Pages ho caricato la mia pagina portfolio (`index.html`), rendendo il case study interattivo accessibile a chiunque via web tramite un semplice link.


## 📁 File del Progetto
Per esplorare il progetto, puoi procedere in due modi: <br>

*Dashboard interattiva*: Nella cartella **Tableau** trovi gli screenshot in anteprima e il link diretto per navigare nel progetto. <br>

*Codice e Logica*: Nella cartella **Query SQL** sono disponibili tutti gli script completi pronti per l'analisi.










