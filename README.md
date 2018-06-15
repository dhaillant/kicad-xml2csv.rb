# kicad-xml2csv.rb
My own KiCad xml to csv BOM generator, made in Ruby language

xml2csv version 20160823

(C) David Haillant

Usage: xml2csv [options]

    -i, --input <kicad_export.xml>   Kicad XML export file
    
    -o, --output <bom.csv>           Generated CSV file. If omitted, <kicad_export.xml>.csv will be created
    
    -g, --group_by <property>        Group components by property
    
    -s, --separator <character>      CSV style separator character. Default is comma.
