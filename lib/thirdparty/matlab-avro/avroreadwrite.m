function avroreadwrite(qn,mySchema)

myWriter = matlabavro.DataFileWriter();
myWriter = myWriter.createAvroFile(mySchema,'myFile.avro');
myWriter.append(qn);
myWriter.close();
myReader = matlabavro.DataFileReader('myFile.avro');
qnfromFile = myReader.next()
end