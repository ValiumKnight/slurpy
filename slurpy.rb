require 'savon'

client = Savon.client(wsdl: "slu.wsdl")

client.call client.operations.first
