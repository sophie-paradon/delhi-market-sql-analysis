-- Delhi Market — analyse SQL / BigQuery
-- Requêtes réellement exécutées pendant l'analyse (voir README.md pour le contexte et les résultats)

-- ============================================================
-- Saisonnalité : CA mensuel
-- ============================================================
SELECT loo.year
     , loo.month
     , SUM(amount) AS total_amount
FROM `Delhimarket.list_of_orders` loo
INNER JOIN `Delhimarket.order_details` od
  ON loo.Order_ID = od.Order_ID
GROUP BY 1, 2
ORDER BY 1, 2;
-- Observation : pic de CA en novembre (Diwali / grandes soldes en Inde), creux en mai.


-- ============================================================
-- CA et profit par catégorie / sous-catégorie
-- ============================================================
SELECT Category
     , od.Sub_Category
     , SUM(amount) AS total_amount
     , SUM(profit) AS total_profit
FROM `Delhimarket.list_of_orders` loo
INNER JOIN `Delhimarket.order_details` od
  ON loo.Order_ID = od.Order_ID
GROUP BY 1, 2;
-- Observation : Electronics génère le plus de CA, mais Clothing génère le plus de profit
-- (volume élevé ≠ marge élevée).


-- ============================================================
-- Panier moyen mensuel (CTE)
-- ============================================================
WITH sales_per_order AS (
  SELECT od.Order_ID
       , loo.month
       , loo.year
       , SUM(amount) AS total_price
  FROM `Delhimarket.list_of_orders` loo
  INNER JOIN `Delhimarket.order_details` od
    ON loo.Order_ID = od.Order_ID
  GROUP BY 1, 2, 3
)
SELECT year
     , month
     , ROUND(AVG(total_price), 2) AS average_basket
FROM sales_per_order
GROUP BY 1, 2;


-- ============================================================
-- Sous-catégories déficitaires (HAVING, filtre post-agrégation)
-- ============================================================
SELECT Sub_Category
     , COUNT(DISTINCT loo.Order_ID) AS nb_orders
     , SUM(amount) AS total_sales
     , SUM(profit) AS total_profit
FROM `Delhimarket.list_of_orders` loo
INNER JOIN `Delhimarket.order_details` od
  ON loo.Order_ID = od.Order_ID
GROUP BY 1
HAVING total_profit < 0;
-- HAVING filtre après l'agrégation (sur le résultat du GROUP BY), contrairement à WHERE.
-- Résultat : Tables et Electronic Games sont en perte sur la période.


-- ============================================================
-- Suivi des objectifs de vente (jointure 3 tables + CASE WHEN, tolérance ±3%)
-- ============================================================
WITH table_sales_target AS (
  SELECT od.category
       , loo.year
       , loo.month
       , target
       , SUM(amount) AS total_sales
  FROM `Delhimarket.list_of_orders` loo
  INNER JOIN `Delhimarket.order_details` od
    ON loo.Order_ID = od.Order_ID
  INNER JOIN `Delhimarket.sales_target` st
    ON od.category = st.category
   AND loo.month = st.month
   AND loo.year = st.year
  GROUP BY 1, 2, 3, 4
),
table_diff_target AS (
  SELECT *
       , CASE
           WHEN total_sales BETWEEN target * 0.97 AND target * 1.03 THEN 'on_target'
           WHEN total_sales > target * 1.03 THEN 'above_target'
           ELSE 'below_target'
         END AS diff_w_target
  FROM table_sales_target
)
SELECT category
     , diff_w_target
     , COUNT(*) AS nb_months
FROM table_diff_target
GROUP BY 1, 2;
-- Jointure sur category + month + year : sans les 3, on créerait un produit cartésien.
-- Observation : below_target domine sur toutes les catégories (Clothing : 9 mois below / 12).


-- ============================================================
-- Bonus — Classement des commandes par CA (fonction fenêtrée RANK)
-- ============================================================
WITH sales_per_order AS (
  SELECT Order_ID
       , SUM(Amount) AS total_sales
  FROM `Delhimarket.order_details`
  GROUP BY 1
)
SELECT *
     , RANK() OVER (ORDER BY total_sales DESC) AS ranking_orders
FROM sales_per_order
ORDER BY ranking_orders;
-- CTE nécessaire : impossible d'appliquer RANK() directement sur un SUM() dans la même requête.


-- ============================================================
-- Bonus — Segmentation des catégories par valeur (CASE WHEN)
-- ============================================================
WITH sales_per_category AS (
  SELECT Category
       , Sub_Category
       , SUM(Amount) AS total_sales
  FROM `Delhimarket.order_details`
  GROUP BY 1, 2
)
SELECT Category
     , total_sales
     , CASE
         WHEN total_sales > 50000 THEN 'High-value'
         WHEN total_sales BETWEEN 20000 AND 50000 THEN 'Medium-value'
         ELSE 'Low-value'
       END AS category_segment
FROM sales_per_category;
