-- Fase 2 del progetto

#Task1.1 La Caccia agli Outliers (Sanity Check)
# (es. odometer minore di 50 miglia o maggiore di 300.000 miglia). Mostro anno, marca, modello, chilometri e prezzo.

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

#Task 1.2: Segmentazione del Mercato (Fasce di Prezzo)

#Seleziono make, model, year, condition e sellingprice.
#creo una nuova colonna chiamata fascia_mercato usando un CASE WHEN: "Low Cost" (sotto i 10.000$) "Mid Range" (tra 10.000$ e 39.999$)"Premium" (sopra i 39.999$)


select year,make,model,condizione,sellingprice,
case
	when sellingprice < 10000 then 'Low cost'
    when sellingprice between 10000 and 39999 then 'Mid range'
    else 'Premium'
end as price_ranges 
from vehicle_sales_clean
order by price_ranges desc ,sellingprice desc ;

#Task 1.3: Volumi e Valori per Brand Vogliamo sapere quali sono i marchi che muovono più soldi e più veicoli.Raggruppo i dati per marca (make).
#Calcolo: il numero totale di auto vendute per quella marca, il prezzo medio di vendita (arrotondato a zero decimali) e il fatturato totale (somma dei prezzi di vendita).



select make,count(*) as cars_sold, round(avg(sellingprice),0) as avg_sellingprince,sum(sellingprice) as total_sales_prices
from vehicle_sales_clean
group by 1
having cars_sold > 1000 
order by total_sales_prices desc;

----------------------------------------------------------------------- Task2---------------------------------------------------------------------------------------------

#Task 2.1: Il "Polso" del Mercato (MMR vs Selling Price)
#Il campo mmr (Manheim Market Report) indica il valore stimato di quell'auto sul mercato. 
#calcolo:
#I volumi (numero di auto vendute).,La differenza media tra il prezzo di vendita reale e il valore di mercato stimato (AVG(sellingprice - mmr)).
#Mostro solo le marche con almeno 500 auto vendute.


select make,count(*) as cars_sold,(avg(sellingprice-mmr)) as avg_margin
from vehicle_sales_clean
group by 1
having cars_sold >500
order by avg_margin desc ;


-------------------------
#Task 2.2: Le Roccaforti (Analisi Geografica) Vogliamo mappare le performance dei nostri hub logistici. Raggruppo i dati per Stato (state).
#Calcolo: numero di vendite, fatturato totale e la condizione media delle auto vendute in quello stato (AVG(condizione)), arrotondata a 1 decimale.


select state,count(*) as number_of_sales,sum(sellingprice) as total_turnover,round(avg(condizione),1) as avg_condition
from vehicle_sales_clean
group by 1
order by total_turnover desc 
limit 5 ;


--------------------------------------------------------------------------
#Task 2.3: Focus sui Top Seller

with general_data as
(select make,count(*) as cars_sold, model, round(avg(sellingprice),0) as avg_sellingprice,sum(sellingprice) as total_sales_prices
from vehicle_sales_clean
group by make,model
having cars_sold > 1000)
select make,model,cars_sold,avg_sellingprice,total_sales_prices from general_data
where make = 'Ford'
order by cars_sold desc 
limit 10 ;

-- ----------------------------------------------------------------------task3------------------------------------------------------------------------------------------

#Livello 3 – Funzioni Finestra e Trend Temporali Task 3.1: La Top 3 Assoluta (Window Functions)

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


-- -------------------------------------------------

#Il Trend Mese-su-Mese (Time Series & LAG)
#Vogliamo vedere come stanno andando le vendite nel tempo. 

with general_date as
(select make,count(*) as cars_sold,year(saledate) as year_sales,monthname(saledate) as month_name_sales,month(saledate) as month_number_sales from vehicle_sales_clean
group by 1,3,4,5),
general_last_month as
(select make,year_sales,month_number_sales,month_name_sales,cars_sold,lag(cars_sold,1)over(partition by make order by year_sales,month_number_sales) as sales_last_month from general_date)
select make,year_sales,month_number_sales,month_name_sales,cars_sold,sales_last_month,
round(((cars_sold - sales_last_month) / sales_last_month) * 100, 2) AS percentage_change
from general_last_month;

-- --------------------
#Task 3.3: L'impatto dei Chilometri sul Deprezzamento
#V#ogliamo dimostrare matematicamente quanto i chilometri distruggono il valore dell'auto.
#Uso un CASE WHEN per creare 4 fasce di chilometraggio (odometer): e calcolo il prezzo medio di vendita (AVG(sellingprice)).


select case 
	when odometer <=50000 then '1_Low_km'
    when odometer <=100000 then '2_Medium_km'
    when odometer <=150000 then '3_High_km'
    else '4_Very_high_km'
end as 'km_bands' ,
round(avg(sellingprice),2) as avg_selling_price from vehicle_sales_clean
group by km_bands
order by km_bands;


-- --------------------------------------------------------Task 4----------------------------------------------------------------------------------------------
#Task 4.1: Le Quote di Mercato (Market Share %)
# in California ('CA'), quanto "pesa" ogni marca sul totale delle auto vendute in quello stato.

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

-- -----------------------------------------
#Task 4.2: Il "Rolling Average" a 3 mesi
#media mobile a 3 mesi per "lisciare" il grafico delle vendite complessive aziendali.
#Raggruppa i dati per anno e mese per trovare il totale delle auto vendute in tutta l'azienda.

with generale as
(select year(saledate) as year_sales,monthname(saledate) as month_name_sales,month(saledate) as month_number_sales,count(*) as cars_sold from vehicle_sales_clean
group by 1,2,3)
select year_sales,month_name_sales,month_number_sales,cars_sold,round(avg(cars_sold)over(order by year_sales asc,month_number_sales asc rows between 2 preceding and current row),0)
as avg_mobile_3Month
from generale ;

-- -------------------------------------------
#Task 4.3: La Caccia all'Affare (Condizioni Complesse)
# auto "sottovalutate" per comprarle e rivenderle.
# un elenco di auto specifiche (VIN, make, model, mmr, sellingprice, condizione) che rispettino tutte queste regole contemporaneamente:
#Condizione eccellente (maggiore o uguale a 45).
#Odometer basso (sotto i 40.000 km).


with discount as
(select vin,make,model,mmr,sellingprice,odometer,condizione,(mmr - sellingprice) AS net_profit_potential,round(((mmr - sellingprice) / mmr) * 100, 2) AS discount_pct from vehicle_sales_clean
having(sellingprice < mmr*0.8))
select vin,make,model,mmr,sellingprice,net_profit_potential,discount_pct,condizione from discount
where condizione>= 45.0 and odometer <40000 
order by condizione desc ;



-- ------------------------------------------------------------- TASK 5 -----------------------------------------------------------------------------------
#Task 5.1: analisi di pareto


#estrarre Il nome del marchio (make). Il fatturato totale di quel marchio.
#Il Fatturato Cumulato (Running Total):
# ovvero, nella riga di Ford ci sarà il fatturato di Ford; nella riga di Chevrolet (seconda) ci sarà il fatturato di Ford + Chevrolet; 
#nella riga di Nissan (terza) ci sarà Ford + Chevrolet + Nissan, e così via fino all'ultima marca.


with general_profit as
(select make,sum(sellingprice) as total_profit from vehicle_sales_clean group by 1 ),
general_running as
(select make,total_profit,sum(total_profit)over(order by total_profit desc) as running_total, SUM(total_profit) OVER () AS absolute_total from general_profit)
select make,total_profit,running_total,round((running_total/absolute_total)*100,2) as cumulative_percentage from general_running;

-- ----------------------------------------------------------------- Task 6 --------------------------------------------------------------------------------------

#segmentazione dei quartili 
#L'Obiettivo:
#Dividere tutte le auto del marchio 'Ford' in 4 gruppi esatti (Quartili) basati sui chilometri percorsi (odometer), dal più basso al più alto.
#Una volta creati questi 4 gruppi, vogliamo calcolare per ciascun gruppo:
#Il numero di auto in quella fascia. Il chilometraggio minimo e massimo di quella fascia. Il prezzo medio di vendita (sellingprice).

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
