--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.
select customer_id, payment_id, payment_date,
       row_number() over (order by payment_date) as "column_1",
       row_number() over (partition by customer_id order by payment_date) as "column_2",
       sum (amount) over (partition by customer_id order by payment_date, amount) as "column_3",
       dense_rank() over (partition by customer_id order by amount desc) as "column_4"
from payment 
order by customer_id, amount desc, payment_date




--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.
select customer_id, payment_id, payment_date, amount,
coalesce (lag (amount) over (partition by customer_id order by payment_date), 0) as "last_amount"
from payment




--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.
select customer_id, payment_id, payment_date, amount,
amount - (lead (amount) over (partition by customer_id order by payment_date)) as "difference"
from payment 




--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.
select customer_id, payment_id, payment_date, amount
from (
select customer_id, payment_id, payment_date, amount,
first_value(payment_id) over (partition by customer_id order by payment_date desc) as "last_id"
from payment) p
where payment_id = p.last_id




--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
select staff_id, payment_date::date, sum (amount) as "sum_amount",
sum (sum (amount)) over (partition by staff_id order by payment_date::date) as "sum"
from payment
where date_trunc('month', payment_date) = '2005-08-01'
group by staff_id, payment_date::date



--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку
select customer_id, payment_date, payment_number
from (
     select *, row_number () over (order by payment_date) as "payment_number"
     from payment 
     where payment_date::date = '2005-08-20') r
where mod (r.payment_number, 100) = 0    



--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм
with cte1 as (
             select p.customer_id, count, sum, max
             from (
                  select customer_id, sum (amount) 
                  from payment
                  group by customer_id) p
             join (
                  select customer_id, count (i.film_id), max(r.rental_date)
                  from rental r
                  join inventory i on r.inventory_id = i.inventory_id 
                  group by customer_id) r on r.customer_id = p.customer_id),
cte2 as (
        select c.customer_id, concat (c.first_name, ' ', c.last_name), c2.country_id,
               case when count = max(count) over (partition by c2.country_id) then concat (c.first_name, ' ', c.last_name) end cc,
               case when sum = max(sum) over (partition by c2.country_id) then concat (c.first_name, ' ', c.last_name) end cs,
               case when max = max(max) over (partition by c2.country_id) then concat (c.first_name, ' ', c.last_name) end cm
        from cte1
        join customer c on cte1.customer_id = c.customer_id
        join address a on a.address_id = c.address_id 
        join city c2 on c2.city_id = a.city_id)
select c.country as "Страна", string_agg(cc, ', ') as "Покупатель, арендовавший наибольшее кол-во фильмов", string_agg(cs, ', ') as "Покупатель, арендовавший фильмов на наибольшую сумму", string_agg(cm, ', ') as "Покупатель, который последним арендовал фильм"
from country c
left join cte2 on cte2.country_id = c.country_id 
group by c.country_id 
order by c.country 
                  
                  





