#!/usr/bin/env ruby
=begin
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require "rexml/document"
require 'forwardable'


$xml2csv_version = "20220524-assembly"

=begin
	Convert a Kicad V4 or V5 XML export file to CSV
=end


class Component
	attr_accessor :ref, :value, :footprint, :datasheet, :extra_fields

	def initialize(ref, value)
		@ref = ref
		@value = value
		@footprint = ""
		@datasheet = ""
		@extra_fields = {}
	end

	def display
		string = @ref + " " + @value

		puts string
	end

	def output_csv file, separator
		@ref.length==0 ? 	file.printf("\"\"%s", separator) : file.printf("\"%s\"%s", @ref, separator)
		@value.length==0 ?	file.printf("\"\"%s", separator) : file.printf("\"%s\"%s", @value, separator)
		@footprint.length==0 ?	file.printf("\"\"%s", separator) : file.printf("\"%s\"%s", @ref, separator)
		@datasheet.length==0 ?	file.printf("\"\"")              : file.printf("\"%s\"",   @ref)

		file.printf("\n")
	end
end

class Components
	extend Forwardable
	include Enumerable

	def_delegators :@components_array, :each, :<<, :push

	def initialize
		@components_array = []
	end

	def display
		@components_array.each do |c|
			c.display
		end
	end

	def display_10_first
		i = 0
		10.times do
			@components_array[i].display
			i += 1
		end

		puts " = " + @components_array.length.to_s + "\n\n"
	end


	def output_csv csv_filename, separator = ","
		csv_file = File.new(csv_filename, "w")

		@components_array.each do |c|
			c.output_csv csv_file, separator
		end

		csv_file.close
	end

	def output_csv_grouped_by field, csv_filename, separator = ","
		# sort by reference :
		sca = @components_array.sort { |a, b| a.ref.to_s <=> b.ref.to_s }

		# number of components with empty extra field
		has_no_value_in_extra_field = 0

		csv_file = File.new(csv_filename, "w")

		# group the components by extra field
		sca.group_by { |c| c.extra_fields[field] }.each_pair do |value, grouped_components|
			if grouped_components[0].extra_fields[field].to_s != "" then
				# print a line to the file
				csv_file.printf("\"%s\"%s%d\n", grouped_components[0].extra_fields[field].to_s, separator, grouped_components.count)

				display_progression
			else
				has_no_value_in_extra_field += grouped_components.count
			end
		end
		csv_file.close

		if has_no_value_in_extra_field > 0 then
			puts "\nWARNING! #{has_no_value_in_extra_field} compnent(s) with no value for #{field}!"
		end
	end


	def output_csv_for_assembly_with field, csv_filename, separator = ","
		# ALPHANUMERIC sort by reference:
		sca = @components_array.sort_by { |a|
			# split LETTERS and NUMBERS (
			letter, number = *a.ref.scan(/\d+|\D+/)
			# compare LETTERS first
			[letter, number.to_i]
		}
		# The regular expression /\d+|\D+/ reads, "match one or more (+) digits (\d) or one or more non-digits (\D).
		# https://stackoverflow.com/questions/64988095/ruby-split-word-to-letters-and-numbers

		# number of components with empty extra field
		has_no_value_in_extra_field = 0

		# open file for write
		csv_file = File.new(csv_filename, "w")

		# write header
		csv_file.printf "Comment,Designator,Footprint,%s\n", field

		# group the components by extra field
		sca.group_by { |c| c.extra_fields[field] }.each_pair do |value, grouped_components|
			if grouped_components[0].extra_fields[field].to_s != "" then
				# print a line to the file (value, list of refs, footprint, extra_field)

				# 1st: value
				csv_file.printf("\"%s\"%s", grouped_components[0].value.to_s, separator)

				# 2nd: list of refs
				csv_file.printf("\"")
				# browse all components and print their "ref"
				for i in 0..grouped_components.count - 1 do
					csv_file.printf("%s", grouped_components[i].ref)

					# if next item exists, add a separator
					if grouped_components[i + 1] then
						csv_file.printf("%s", separator)
					end
				end
				csv_file.printf("\"%s", separator)

				# 3rd: footprint
				csv_file.printf("\"%s\"%s", grouped_components[0].footprint.to_s, separator)

				# 4th: extra field
				csv_file.printf("\"%s\"\n", grouped_components[0].extra_fields[field].to_s)

				display_progression
			else
				has_no_value_in_extra_field += grouped_components.count
			end
		end
		csv_file.close

		if has_no_value_in_extra_field > 0 then
			puts "\nWARNING! #{has_no_value_in_extra_field} compnent(s) with no value for #{field}!"
		end
	end


	def read_xml xml_filename
		xml_file = File.new(xml_filename)
		doc = REXML::Document.new xml_file

		print "Loading XML file #{xml_filename}...\n"
		xml_components = doc.elements.to_a("export/components/comp")

		xml_components.each do |xml_comp|
			c = Component.new xml_comp.attribute("ref").to_s, xml_comp.elements["value"].text

			c.footprint = xml_comp.elements["footprint"].text unless xml_comp.elements["footprint"].nil?
			c.datasheet = xml_comp.elements["datasheet"].text unless xml_comp.elements["datasheet"].nil?


			xml_extra_fields = xml_comp.elements.to_a("fields/field")
			xml_extra_fields.each do |xml_extra_field|
				extra_field = {
					:name => xml_extra_field.attribute("name").to_s,
					:value => xml_extra_field.text
				}
				c.extra_fields[extra_field[:name]] = extra_field[:value]
			end

			@components_array.push c
			display_progression
		end
	end
end



def display_progression
	STDOUT.sync = true
	print "."
end



puts "xml2csv version " + $xml2csv_version
puts "(C) David Haillant"
puts "\n"



require 'optparse'
options = {}
OptionParser.new do |opt|
	opt.on('-i', '--input <kicad_export.xml>',	'Kicad XML export file.')						{ |i| options[:xml_filename] = i }
	opt.on('-o', '--output <bom.csv>',		'Generated CSV file. If omitted, <kicad_export.xml>.csv will be used.')	{ |o| options[:csv_filename] = o }
	opt.on('-g', '--group_by <property field>',	'Group components by property field.')					{ |g| options[:groupby_field] = g }
	opt.on('-s', '--separator <character>',		'Separator character. Default is comma.')				{ |s| options[:separator] = s }

	opt.on('-a', '--assembly',	'Generates a BOM for Assembly. --group_by option is mandatory.') do |a|
		options[:assembly] = a
	end

	opt.on("-h", "--help", "Prints this help.") do
		puts opt
		exit
	end
end.parse!

#p options

if options[:xml_filename] then

	components = Components.new
	components.read_xml options[:xml_filename]

	puts "\n#{components.count} components found\n\n"

	# setting default values if options not explicitely specified
	options[:csv_filename] ? csv_filename = options[:csv_filename] : csv_filename = options[:xml_filename] + ".csv"
	options[:separator] ? separator = options[:separator] : separator = ','

	puts "CSV output file: #{csv_filename}, using '#{separator}' as separator"

	print "Writing CSV file..."


	if options[:groupby_field] then
		if options[:assembly] then
			components.output_csv_for_assembly_with options[:groupby_field], csv_filename, separator
		else
			components.output_csv_grouped_by options[:groupby_field], csv_filename, separator
		end
	else
		components.output_csv csv_filename, separator
	end

	puts "\nDone!\n\n"

else
	puts "Requires at least Kicad XML export filename. Please use -h to see help"
end
