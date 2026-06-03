-- ---------------------------------------CREAZIONE VISTE PER TABLEAU E RI-UTILIZZO CODICE PER ALTRE ANALISI DETTAGLIATE SU MY SQL------------------------------------------------
-- VISTA  1 per ogni stato e la sua percentuale per ogni marca e auto venduta, il suo impatto.-- ---------------------------------------
CREATE VIEW vw_market_share_state AS
select state,make,count(*) as cars_sold,ROUND((COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY state)) * 100, 2) 
as state_market_share_pct
from vehicle_sales_clean
where state is not null and make is not null
group by state, make;

SELECT*from vw_market_share_state;

-- -------------- Vista  2 media mobile di auto vendute per mese e anno -- ---------------------------------------
CREATE VIEW vw_sales_trend_rolling as
(with generale as
(select year(saledate) as year_sales,monthname(saledate) as month_name_sales,month(saledate) as month_number_sales,count(*) as cars_sold from vehicle_sales_clean
group by 1,2,3)
select year_sales,month_name_sales,month_number_sales,cars_sold,round(avg(cars_sold)over(order by year_sales asc,month_number_sales asc rows between 2 preceding and current row),0)
as avg_mobile_3Month
from generale);

SELECT*from vw_sales_trend_rolling;


-- ---------------- Vista 3 , contiene tutte le auto con i relativi vin vendute  a un prezzo di mercato inferiore-- ---------------------------------------

CREATE VIEW vw_arbitrage_opportunities AS
(with discount as
(select vin,make,model,mmr,sellingprice,odometer,condizione,(mmr - sellingprice) AS net_profit_potential,round(((mmr - sellingprice) / mmr) * 100, 2) AS discount_pct from vehicle_sales_clean
having(sellingprice < mmr*0.8))
select vin,make,model,mmr,sellingprice,net_profit_potential,discount_pct,condizione from discount
where condizione>= 45.0 and odometer <40000 
order by condizione desc);

SELECT*from vw_arbitrage_opportunities ;

-- -------------------------------------------- Vista 4, pareto revenue, query che mostra la regola di parete, ovvero l'80 % dei guadagni viene dal 20% dei prodotti. La tabbella afferma cio -- ---------------------------------------
use automotive_analytics;
CREATE VIEW vw_pareto_revenue AS
(with general_profit as
(select make,sum(sellingprice) as total_profit from vehicle_sales_clean group by 1 ),
general_running as
(select make,total_profit,sum(total_profit)over(order by total_profit desc) as running_total, sum(total_profit) over () AS absolute_total from general_profit)
select make,total_profit,running_total,round((running_total/absolute_total)*100,2) as cumulative_percentage from general_running);

SELECT*from vw_pareto_revenue ;

-- --------------------------------------------- Vista 5  abbiamo 4 quartili divisi per chilometri percorsi di ogni auto, con il suo min e max di chilometri per ogni quartile e il relativo prezzo di vendita -- ---------------------------------------

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


-- ---------------------------------------------------------------------VIsta 6, identica alla 5 ma aggiungendo le varie marche ( make) --------------------------------------------
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


-- -----------------------------------------------------------------VISTA 7 , UGUALE al market share state ma senza make ----------------------------------------------------------

CREATE VIEW vw_market_share_for_state AS
(with generale as
(select state, count(*) as cars_sold, round(avg(sellingprice),2) as avg_selling_price
from vehicle_sales_clean
group by 1)
select state,cars_sold,avg_selling_price,round((cars_sold/ SUM(SUM(cars_sold)) OVER())* 100,2) AS state_market_share_pct  from generale 
group by 1);

select*from vw_market_share_for_state ;





-- --------------------------------------------- vista 8-  simile alla 6 ma con aggiunta di state, questo utile per le fasi successive su tableau-------------------------------------

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




