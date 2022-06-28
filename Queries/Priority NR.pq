let
// подготовим таблицу с комбинациями кост центров и месяцев
    OU_names = Table.SelectColumns ( #"Firm structure 03 Segment-BU", "OU name"),
    months = Table.SelectColumns ( 
        Table.SelectRows(
// выберем только месяцы текущего года
            #"DimMonths", each [Year is current] = true
        ), 
        "Year-month"),
    #"Added cross join" = 
        Table.AddColumn(
            OU_names, "Cross join", each months,
            type table
            ),
    #"Join OU and period combinations" =  
        Table.ExpandTableColumn(
            #"Added cross join", 
            "Cross join", 
            {"Year-month"}, 
            {"Year-month"}),

// ТАБЛИЦА с месяцами и OU            
    #"OU and period combinations" = Table.TransformColumnTypes(#"Join OU and period combinations",{{"Year-month", type text}}),

// подготовим таблицу с Total NR
    #"Filter accounts" =  Table.SelectRows(#"Metrics by CC", each ([Account name] = "Net Revenue")),
    #"Total NR" = Table.SelectColumns(#"Filter accounts",{"OU name", "Year-month", "Actual", "PY"}),

// подготовим таблицу с Priority clients NR
    #"Priority NR" = Table.Group(
        #"Priority clients NR and client", 
        {"OU name", "Year-month", "Priority segment"}, 
        {{"NR actual", each List.Sum([NR actual]), type number}, 
        {"NR PY", each List.Sum([NR PY]), type number}}),

// собираем месяцы и total NR
    #"Months and total NR" = 
    Table.NestedJoin(
        #"OU and period combinations", 
        {"OU name", "Year-month"}, 
        #"Total NR",
        {"OU name", "Year-month"}, 
        "Total NR", 
        JoinKind.LeftOuter),
// ТАБЛИЦА с месяцами и OU c Total NR        
    #"Expanded Total NR" = Table.ExpandTableColumn(#"Months and total NR", "Total NR", {"Actual", "PY"}, {"Total NR.Actual", "Total NR.PY"}),

// собираем месяцы, Total NR и Priority NR
     #"Total NR and priority NR" = 
    Table.NestedJoin(
        #"Expanded Total NR", 
        {"OU name", "Year-month"}, 
        #"Priority NR",
        {"OU name", "Year-month"}, 
        "Priority NR", 
        JoinKind.LeftOuter),

// ТАБЛИЦА с полной информацией по месяцам и OU - весь NR и NR от приоритетных клиентов
    #"Expanded Priority NR" = Table.ExpandTableColumn(#"Total NR and priority NR", "Priority NR", {"NR actual", "NR PY"}, {"Priority NR.Actual", "Priority NR.PY"}),

    #"Replaced nulls with 0" = Table.ReplaceValue(
        #"Expanded Priority NR",null,0,Replacer.ReplaceValue,
        {"Total NR.Actual", "Total NR.PY", "Priority NR.Actual", "Priority NR.PY"}),
    #"Added NR Act without priority" = Table.AddColumn(
        #"Replaced nulls with 0", "NR actual", 
        each [Total NR.Actual] - [Priority NR.Actual], type number),
    #"Added NR PY without priority" = Table.AddColumn(
        #"Added NR Act without priority", "NR PY", 
        each [Total NR.PY] - [Priority NR.PY], type number),
    #"Removed Other Columns" = Table.SelectColumns(#"Added NR PY without priority",{"OU name", "Year-month", "NR actual", "NR PY"}),
    #"Added priority segment" = Table.AddColumn(#"Removed Other Columns", "Priority segment", each "Other", type text),
    #"Appended Priority NR" = Table.Combine(
            {#"Added priority segment", 
            Table.SelectColumns( 
                #"Priority clients NR and client",
                {"OU name", "Year-month", "NR actual", "NR PY", "Priority segment"})
           }),
    #"Filtered Rows" = Table.SelectRows(#"Appended Priority NR", each true)

in
   #"Filtered Rows"
