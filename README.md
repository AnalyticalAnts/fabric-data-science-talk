# Financial Modeling in Microsoft Fabric

Companion files for **Financial Modeling in Microsoft Fabric**, a talk given by
William Rodriguez (Analytical Ants) at the Atlanta Microsoft Business
Intelligence Users meetup on December 4, 2023.

- Video: https://youtu.be/5G3oRfWKY4U
- Write-up: https://analyticalants.com/blog/financial-modeling-in-microsoft-fabric
- Analytical Ants: https://analyticalants.com

The talk takes a synthetic retail general ledger from raw CSV to a Profit &
Loss, Balance Sheet, Cashflow Statement and corporate valuation, using one
Microsoft Fabric workspace: Dataflow Gen2, a lakehouse (bronze, silver, gold),
a Spark notebook with Data Wrangler, a data pipeline and a Direct Lake Power BI
report. It closes the Financial Modeling with Microsoft Business Intelligence
series on analyticalants.com.

> These files reflect Microsoft Fabric as it was in December 2023. Menus,
> trial terms and Direct Lake limits have changed since; check current
> Microsoft documentation as you go.

## What's in this repository

| Folder       | Contents                                                                                     |
| ------------ | -------------------------------------------------------------------------------------------- |
| `slides/`    | The talk deck (PDF). *Coming soon, after cleanup.*                                           |
| `dataflow/`  | `dataflow-gen2-queries.pq`: the Power Query (M) for every silver table                       |
| `notebooks/` | `2_Notebook_Engineering.ipynb`: Spark SQL joins, anomaly flags, the gold write, Data Wrangler |
| `powerbi/`   | The report: three financial statements, their ratios and a valuation page. *Coming soon.*    |

All data is synthetic. The general ledger and budget come from the public
[Randomized Retail GL Generator](https://github.com/AnalyticalAnts/Randomized-Retail-GL-Generator);
no real company's books are included. Workspace, lakehouse and session IDs and
saved notebook outputs have been removed.

## Rebuild it in your own Fabric workspace

1. Start a [Microsoft Fabric trial](https://learn.microsoft.com/en-us/fabric/fundamentals/fabric-trial)
   (or use any Fabric capacity) and create a workspace on it.
2. Create a lakehouse named `FinancialModeling`. The notebook's Spark SQL uses
   that name.
3. Create a **Dataflow Gen2**. Add one blank query per section of
   `dataflow/dataflow-gen2-queries.pq` (each section starts with `--<QueryName>`),
   paste the M and give the query that name. Mark `Staging - General Ledger` as
   staging only, and send the `*_Silver` queries to the lakehouse as tables.
   Use table names without spaces.
4. Import `notebooks/2_Notebook_Engineering.ipynb` into the workspace, attach it
   to the `FinancialModeling` lakehouse and run it. It writes
   `GeneralLedger_Gold`.
5. Create a **data pipeline** that runs the dataflow, then the notebook.
6. Open the Power BI file in Power BI Desktop and point it at your own
   lakehouse's semantic model (or rebuild the model on your gold and silver
   tables). XMLA read-write must be enabled on the capacity to edit a Direct
   Lake model from external tools.

## The series

1. [Financial Modeling in Business Intelligence (part 1)](https://analyticalants.com/blog/231016-financial-modeling-in-business-intelligence-part-1)
2. [Financial Modeling in Excel (part 2)](https://analyticalants.com/blog/231018-financial-modeling-in-excel-part-2)
3. [Financial Modeling in Power BI (part 3)](https://analyticalants.com/blog/231027-financial-modeling-in-power-bi-part-3)
4. [Discounted Cash Flows in Power BI](https://analyticalants.com/blog/231114-discounted-cash-flows-in-power-bi-part-1)
5. Financial Modeling in Microsoft Fabric (this talk)

## Need help with Fabric or Power BI?

Analytical Ants designs data platforms, Power BI models and data science work.
Tell us about your project at https://analyticalants.com/contact.

## License

<!-- OWNER DECISION: suggested MIT for code (M, notebook) and CC BY 4.0 for the
slides and report. Replace this block with the chosen LICENSE before publishing. -->

Copyright © 2023–2026 Analytical Ants LLC.
