# kicad-xml2csv.rb
KiCad "xml to csv" BOM generator, made in Ruby language

The main purpose of this tool is to export one field from the BOM, with the number of components with the same value.
Typically, this is useful for importing the BOM to suppliers' websites "quick buy" feature:
Add a custom field named after your favorite supplier, and fill in the supplier's component reference.

This script uses **Ruby**, with *REXML* and *forwardable*

Compatible with KiCad 4, 5 and 6


> xml2csv version 20220524
> 
> Usage: xml2csv [options]
> 
>    -i, --input <kicad_export.xml>   Kicad XML export file
> 
>    -o, --output <bom.csv>           Generated CSV file. If omitted, <kicad_export.xml>.csv will be created
> 
>    -g, --group_by <field>        Group components by field
> 
>    -s, --separator <character>      CSV style separator character. Default is comma.

With version 20220524:

* In "group_by" mode, the number of components with an empty field is now only display on screen and removed from CSV output.
* Separator now works also for standard mode too.

