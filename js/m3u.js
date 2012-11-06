var m3u = function(targetID, m3uPath, sequential) {
	m3u.files;
	m3u.current_file = 0;

	m3u.parse = function(data, status) {
		files = data.split('\n');
		var target = document.getElementById(targetID);
		if (sequential) {
			target.innerHTML = this.drawOne(this.current_file)+this.drawControls(this.current_file);
		} else {
			target.innerHTML = this.drawAll();
		}

	}
	m3u.drawControls = function(i) {
		var text = '<div class="control">'; 
		if (i < files.length-1) {
			text += '<a href="#" onclick="m3u.gotoFile('+i+1+')">&gt;</a>';
		}
		if (i > 0) {
                        text +='<a href="#" onclick="m3u.gotoFile('+i-1+')">&lt;</a>';
                }
		text += '</div>';
		return text;
	}
	m3u.cleanupFiles = function() {
		var fn = [];
		for (var i =0; i<files.length; i++) 
		{
			if (files[i]) {
				fn+=files[i];
			} else {
				if (this.current_file>=i) {
					this.current_file--;
				}
			}
		}
		files = fn;
	}
	m3u.gotoFile = function(i) {
		this.current_file = i;
		this.cleanupFiles();
		var target = document.getElementById(targetID);
                target.innerHTML = this.drawOne(this.current_file)+this.drawControls(this.current_file);
	}
	m3u.drawOne = function(i) {
		var url = files[i];
                if (url) {
			var parts = url.split('/');
	                var name = parts[parts.length-1];
//                      url = parts[0];
//                      for (var j=1; j<parts.length-1;j++) {
//                      	url += '/'+escape(parts[j]);
//                      }
                        var type = this.testURL(url);
                        if(type) {
                        	return this.getPlayerText(url, name, type);
                        } else {
				files[i] = false;
				if (i<files.length-1) {
					return this.drawOne(i+1);
				}
			}
        	}
	}
	m3u.drawAll = function() {
                var text = '<ul>';
                for (var i=0;i<files.length;i++) {
                	text += '<li>'+drawOne(i)+'</li>';
                }
		text += '</ul>';
		return text;
	}
	m3u.getPlayerText = function(url, name, type, id) {
		var text = '<audio name="audio_'+id+'" controls="controls">';
		text += '<source src="'+url+'" type="'+type+'" ';
		text += 'preload="metadata" /></audio>';
		text += '<label><a href="'+url+'" target="_blank">';
		text += name;
		text += '</a></label>';
		return text;
	}
	m3u.testURL = function(url) {
		var http = new XMLHttpRequest();
		http.open('HEAD', url, false);
		http.send();
		if (http.status==404) return false;
		return http.getResponseHeader('content-type');
	}
//	var request = jQuery.ajax('relative.m3u', {'success' : parse});
	var request = new XMLHttpRequest();
	request.open('GET',m3uPath+'?rand='+Math.random(), false)
	request.setRequestHeader("Cache-Control","no-cache,max-age=0");
	request.setRequestHeader("Pragma", "no-cache");
	request.send();
	if (request.status == 200) {
		m3u.parse(request.responseText, request.status);
	}
}
