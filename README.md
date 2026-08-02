# Delhi Market — Analyse SQL / BigQuery

Analyse de la croissance et de la rentabilité d'une marketplace e-commerce indienne : **Electronics génère le plus de chiffre d'affaires, mais Clothing est la catégorie la plus rentable**, et les objectifs de vente sont ratés sur la quasi-totalité des catégories.

*Projet réalisé dans le cadre de la formation Data Analyst DataBird.*

## Contexte
Stéphanie a racheté en avril 2018 une marketplace e-commerce en Inde (Delhi Market, sur Shopify). Elle a extrait 3 fichiers de données (commandes, détail des commandes, objectifs mensuels de vente par catégorie) et veut mesurer la croissance de son activité depuis le rachat et identifier ses leviers de rentabilité.

## Compétences mobilisées
- SQL / BigQuery : `JOIN`, `GROUP BY` / `HAVING`, agrégations (`SUM`, `COUNT DISTINCT`)
- Window function `RANK()` pour classer les commandes
- `CASE WHEN` pour classifier les produits (High/Medium/Low value)
- Analyse de saisonnalité et croisement réalisé vs objectifs

## Exemple de requête — chiffre d'affaires mensuel
```sql
SELECT loo.year, loo.month, SUM(amount) AS total_amount
FROM Delhimarket.list_of_orders loo
INNER JOIN Delhimarket.order_details od
  ON loo.`Order ID` = od.`Order ID`
GROUP BY 1, 2
ORDER BY 1, 2;

Résultats

- Electronics génère le plus de CA mais avec des marges faibles ; Clothing est la catégorie la plus rentable
- Activité fortement saisonnière : CA au pic en novembre (période Diwali), au plus bas en mai
- below_target domine sur presque toutes les catégories (ex. Clothing : 9 mois sur 12 en dessous de l'objectif)
- Recommandation : revoir les objectifs de vente à la baisse pour les aligner avec la réalité du marché, plutôt que de continuer à viser une croissance non tenable

Outils

BigQuery, SQL
