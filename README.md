# kicad-xml2csv.rb
KiCad "xml to csv" BOM generator, made in Ruby language
Compatible with KiCad 4, 5 and 6

xml2csv version 20220524

(C) David Haillant

Usage: xml2csv [options]

    -i, --input <kicad_export.xml>   Kicad XML export file
    
    -o, --output <bom.csv>           Generated CSV file. If omitted, <kicad_export.xml>.csv will be created
    
    -g, --group_by <field>        Group components by field
    
    -s, --separator <character>      CSV style separator character. Default is comma.



With version 20220524:
In "group_by" mode, the number of components with an empty field is now only display on screen and removed from CSV output.
Separator now works also for standard mode too.

