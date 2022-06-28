let
    Source = AnalysisServices.Database("ceeireporterpowerbi", "GLAnalysisTB", [TypedMeasureColumns=true, Implementation="2.0"]),
    GlAnalysisTB = Source{[Id="GlAnalysisTB"]}[Data],
    GlAnalysisTB1 = GlAnalysisTB{[Id="GlAnalysisTB"]}[Data],
    #"Added Items" = Cube.Transform(GlAnalysisTB1,
        {
            {Cube.AddAndExpandDimensionColumn, "[Time]", {"[Time].[Actual Fiscal Month].[Actual Fiscal Month]", "[Time].[Actual Fiscal Year].[Actual Fiscal Year]", "[Time].[Month Name].[Month Name]", "[Time].[YTD Closed Reporting Months].[YTD Closed Reporting Months]"}, {"Time.Actual Fiscal Month", "Time.Actual Fiscal Year", "Time.Month Name", "Time.YTD Closed Reporting Months"}}
        }),
    #"Extracted First Characters" = Table.TransformColumns(#"Added Items", {{"Time.Month Name", each Text.Start(_, 7), type text}}),
    #"Renamed Columns" = Table.RenameColumns(#"Extracted First Characters",{{"Time.Month Name", "Year-month"}}),
    #"Filtered Rows" = Table.SelectRows(#"Renamed Columns", each (Cube.AttributeMemberId([Time.YTD Closed Reporting Months]) <> "[Time].[YTD Closed Reporting Months].&" meta [DisplayName = "(null)"])),
    #"Sorted Rows" = Table.Sort(#"Filtered Rows",{{"Year-month", Order.Descending}})
in
    #"Sorted Rows"
