--------------------------
--Staging - General Ledger

let
  Source = Csv.Document(Web.Contents("https://raw.githubusercontent.com/AnalyticalAnts/Randomized-Retail-GL-Generator/main/Synthetic_Retail_GL_Data_ML.csv"), [Delimiter = ",", Columns = 7, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
  #"Changed column type" = Table.TransformColumnTypes(#"Promoted headers", {{"BATCH", Int64.Type}, {"DATE", type text}, {"ACCOUNT", type text}, {"ACCOUNT DESCRIPTION", type text}, {"DR", type number}, {"CR", type number}, {"", type text}}),
  #"Removed columns" = Table.RemoveColumns(#"Changed column type", {""})
in
  #"Removed columns"

--------------------------
--GeneralLedger_Silver

let
  Source = #"Staging - General Ledger",
  #"Filtered rows" = Table.SelectRows(Source, each ([DATE] <> "Description:")),
  #"Changed column type" = Table.TransformColumnTypes(#"Filtered rows", {{"DATE", type date}, {"ACCOUNT", Int64.Type}}),
  #"Removed columns" = Table.RemoveColumns(#"Changed column type", {"ACCOUNT DESCRIPTION"}),
  #"Renamed columns" = Table.RenameColumns(#"Removed columns", {{"BATCH", "Batch"}, {"DATE", "Date"}, {"ACCOUNT", "Account"}})
in
  #"Renamed columns"

--------------------------
--TransactionDescription_Silver

let
  Source = #"Staging - General Ledger",
  #"Filtered rows" = Table.SelectRows(Source, each ([DATE] = "Description:")),
  #"Removed columns" = Table.RemoveColumns(#"Filtered rows", {"DR", "CR", "DATE"}),
  #"Renamed columns" = Table.RenameColumns(#"Removed columns", {{"ACCOUNT", "DESCRIPTION"}, {"ACCOUNT DESCRIPTION", "ANOMALY INDICATOR"}})
in
  #"Renamed columns"

--------------------------
--ChartofAccounts_Silver

let
  Source = #"Staging - General Ledger", 
    #"Filtered Rows" = Table.SelectRows(Source, each ([DATE] <> "Description:")),
    
    #"Changed Type1" = Table.TransformColumnTypes(#"Filtered Rows",{{"DATE", type date}, {"ACCOUNT", Int64.Type}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type1",{{"BATCH", "Batch"}, {"DATE", "Date"}, {"ACCOUNT", "Account"}, {"ACCOUNT DESCRIPTION", "Account Description"}}), 
    #"Removed Other Columns" = Table.SelectColumns(#"Renamed Columns",{"Account", "Account Description"}),
    #"Grouped Rows" = Table.Group(#"Removed Other Columns", {"Account", "Account Description"}, {{"Count", each Table.RowCount(_), Int64.Type}}),
    #"Removed Columns1" = Table.RemoveColumns(#"Grouped Rows",{"Count"}),
    #"Sorted Rows" = Table.Sort(#"Removed Columns1",{{"Account", Order.Ascending}}),
    #"Added AccountType" = Table.AddColumn(#"Sorted Rows", "Account Type", each if [Account] >= 501 then "Expense" else if [Account] >= 401 then "Revenue" else if [Account] >= 301 then "Owner's Equity" else if [Account] >= 201 then "Liability" else "Asset", type text), 
    #"Added DebitIndicator" = Table.AddColumn(#"Added AccountType", "Debit Increase Indicator", each if List.Contains({"Expense", "Asset"}, [Account Type]) then 1 else 0, Int64.Type)
in
    #"Added DebitIndicator"

--------------------------
--Budgets_Silver

let
    Source = Csv.Document(Web.Contents("https://raw.githubusercontent.com/AnalyticalAnts/Randomized-Retail-GL-Generator/main/Synthetic_Budget_Data.csv"),[Delimiter=",", Columns=4, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Removed Columns" = Table.RemoveColumns(#"Promoted Headers",{"ACCOUNT DESCRIPTION"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"YEAR", Int64.Type}, {"ACCOUNT", Int64.Type}, {"BUDGET AMOUNT", type number}}), 


    StartProperCase = #"Changed Type",
    ColNames = Table.ColumnNames(StartProperCase),
    ProperNames = List.Transform(ColNames, each Text.Proper(_)),
    EndProperCase = Table.RenameColumns(StartProperCase, List.Zip({ColNames, ProperNames}))
in
    EndProperCase

--------------------------
--Calendar_Silver

let
MinDate = List.Min(GeneralLedger_Silver[Date]),
    StartOfYearDate = #date(Date.Year(MinDate), 1, 1),
    MaxDate = List.Max(GeneralLedger_Silver[Date]),
    EOYMaxDate = #date(Date.Year(MaxDate), 12, 31),  // End of Year of Max Date
    NewMaxDate = Date.AddYears(EOYMaxDate, 20),  // Adding 10 years to Max Date
    NumberOfDates = Duration.Days(NewMaxDate - StartOfYearDate) + 1,  // Calculating number of dates,
    DatesList = List.Dates(StartOfYearDate, NumberOfDates, #duration(1,0,0,0)),
    DateTable = Table.FromList(DatesList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    RenamedTable = Table.RenameColumns(DateTable,{{"Column1", "Date"}}),
    #"Changed Type" = Table.TransformColumnTypes(RenamedTable,{{"Date", type date}}),
    #"Inserted Year" = Table.AddColumn(#"Changed Type", "Year", each Date.Year([Date]), Int64.Type),
    #"Add Month Name" = Table.AddColumn(#"Inserted Year", "Month Name", each Date.MonthName([Date]), type text),
    #"Add Month Number" = Table.AddColumn(#"Add Month Name", "Month", each Date.Month([Date]), type number),
    #"Add YYYY-MM" = Table.AddColumn(#"Add Month Number", "YYYY-MM", each Text.Combine({Date.ToText([Date], "yyyy"), "-", Date.ToText([Date], "MM")}), type text),
    #"Add Week" = Table.AddColumn(#"Add YYYY-MM", "YYYY-WW", each Text.Combine({Date.ToText([Date], "yyyy"), "-", Number.ToText(Date.WeekOfYear([Date]), "00")}), type text),
    #"Added Custom Column" = Table.AddColumn(#"Add Week", "Custom", each Text.Combine({Date.ToText([Date], "MMM"), " '", Date.ToText([Date], "yy")}), type text),
    #"Renamed Columns" = Table.RenameColumns(#"Added Custom Column",{{"Custom", "Short Month Year"}})
in
    #"Renamed Columns"

--------------------------
--FinancialStatements_Silver

let
    Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("vVVNT+MwEP0ro54WqYeSwHLuAlshdZeKHDiwHNxkQkdy7WJP2q3Ej8cO2yYRTvqFVkpTeWy/N37jN3l66k2MzolBqAzG2tpev5cIiRYecImqQDcOhC4G5+5d/Z77IaBrbRl0DiOtMwuJlpkL3pDBlMHPta65LOGjHfAj4/7hlzAvpLrSjA/G6UhqF9j9Ao1gUi9w+3eBymKpKErpQn0YoXLTsg9/isEg+g7DbE6KLPstS6xveUDFm3FJ7tW4+E/kTkdh1g36eA/638hwp1I9R/jmQ2ddVbk8DqyjNEciBpU+EqtFuCbaD7dIpQjJDJFddGgtfnihMMYnUwWEnfltAbftDzJMU10o9hVIkZZiKrHEjGqY0YGYd8oVk7VZl0hxDSkOIo1JTEkSk7sIXsX7lbuKFm5fC+J1c76e8USs/6UbBTrCaSRjLVSDIKoRhPXYRRAcl2a7qkXj7VGi7VF8oXOpV5CwYJw7bRtuHqbOoZvE/VrIjZ7DdWHZ3UATatqhDn06y/536WCuiaAMcm12NsHz05QL8bTYtqrT8UysISkWC0kfAna0r+rr8mVsYZvGX3ukVrduuOJ2Lp+g/cy1faqPXivET1LOpJ8gfIMuLd6IBk1fdehDSUqDQ6oVG5oWTFpZeINH4llmxGq7oqUFbHhdLZ7fAQ==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [#"Financial Statement" = _t, Category = _t, Subcategory = _t, Detail = _t, Account = _t, #"Category Order" = _t, #"Subcategory Order" = _t, #"Detail Order" = _t]),
    #"Changed Type" = Table.TransformColumnTypes(Source,{{"Financial Statement", type text}, {"Category", type text}, {"Subcategory", type text}, {"Account", Int64.Type}, 
        {"Category Order", Int64.Type}, {"Subcategory Order", Int64.Type}, {"Detail Order", Int64.Type}}),
    #"Add: Detail Sorted Column" = Table.AddColumn(#"Changed Type", "Detail Sorted (VizOnly)", each Text.Repeat(Character.FromNumber(8203), [Detail Order]) & Text.From([Detail])),
  #"Changed column type" = Table.TransformColumnTypes(#"Add: Detail Sorted Column", {{"Detail Sorted (VizOnly)", type text}})
in
    #"Changed column type"

--------------------------
--Competitors_Silver

// Removed from the public copy pending owner review: the original query embedded
// comparable-company figures and Crunchbase links for real listed companies.
// Add your own comparables table here (columns: Company, Stock Sym, Market Cap,
// Enterprise Value, Revenue, EBITDA, Net Income, Total Cash, Total Debt).
