function model = jsimgEdit
fname = [tempname,'.jsimg'];
copyfile(which('emptyModel.jsimg'),fname);
jsimgView(fname);
try
    model = JMT2LINE(fname);
    delete(fname);
catch
    error('Error: JMT2LINE failed. JMT model stored at: %s',fname)
end
end