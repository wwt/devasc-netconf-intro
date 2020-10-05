#!/usr/bin/env python3

import xmltodict
from pprint import pprint

data = '''
<?xml version="1.0" ?>
 <root>
  <agenda>
   <items>
    <item>NETCONF Protocol</item>
    <item>NETCONF Tools</item>
    <item>Hands-On Lab</item>
    <item>Q &amp; A</item>
    <item>Homework</item>
   </items>
  </agenda>
 </root>
 '''

xml_data = data.strip()
py_data = xmltodict.parse(xml_data, dict_constructor=dict)

print()
print('** Raw XML Data **')
print(xml_data)
print()

print('** Python Data **')
pprint(py_data)
print()

print('** "items" Python Object Type **')
print(type(py_data['root']['agenda']['items']))
print()

print('** "item" Python Object Type **')
print(type(py_data['root']['agenda']['items']['item']))
print()
