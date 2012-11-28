var m3u = function(targetID, m3uPath, sequential) {
	m3u.files;
	m3u.current_file = 0;
	m3u.dates = [];
	m3u.sizes = [];

	m3u.parse = function(data, status) {
		files = data.split('\n');
		var target = document.getElementById(targetID);
		this.testAllURLs();
		if (sequential) {
			target.innerHTML = '<div id="player">'+this.drawOne(this.current_file, true)+this.drawControls(this.current_file, true);
		} else {
			target.innerHTML = this.drawAll();
		}

	}
	m3u.drawControls = function(i, extraDivEnd) {
		var text = '<div class="control">'; 
		if (i > 0) {
                        text +='<a href="#" onclick="m3u.gotoFile('+(i-1)+')">&lt;</a>';
                }
		text += '&nbsp;<span class="help">Datei '+(i+1)+' von '+files.length+'</span>&nbsp;'
		if (i < files.length-1) {
                        text += '<a href="#" onclick="m3u.gotoFile('+(i+1)+')">&gt;</a>';
                }
		text += '</div>';
		if (extraDivEnd) {
			text += '</div>';
		}
		text += this.drawList(i);
		return text;
	}
	m3u.drawList = function(i) {
		var text = '<ol class="playlist">'
		for (var j=0;j<files.length;j++) {
			if (files[j]) {
				var feed = this.getFeedname(j);
				var inner;
				if (feed) {
					inner = '<span class="feed">'+feed+'</span>';
				}
				inner += '<span class="episode">'+this.getFilename(j)+'</span>';
				date = this.dates[files[j]];
				size = this.sizes[files[j]];
                                if (date) {
                                	inner += '<span class="date data">'+date+'</span>';
                                } else {
					inner += '<span class="empty"></span>';
				}
				if (size) {
					inner += '<span class="size data">'+Math.round((size/(1024*1024)*10))/10+' MB</span>';
				} else {
					inner += '<span class="empty"></span>';
				}
				if (i==j) {
					text += '<li class="active">'+inner+'</li>';
				} else {
					text += '<li class="inactive" onclick="m3u.gotoFile('+(j)+')">'+inner+'</li>';
				}
			}
		}
		text += '</ol>';
		return text;
	}
	m3u.cleanupFiles = function() {
		var fn = [];
		for (var i =0; i<files.length; i++) 
		{
			if (files[i]) {
				fn[fn.length] =files[i];
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
                target.innerHTML =  '<div id="player">'+this.drawOne(this.current_file, true)+this.drawControls(this.current_file, true);
		var player = document.getElementById('media_'+i);
		if (player) {
			if (i+1 < files.length) {
				player.addEventListener('ended', function() {m3u.gotoFile(i+1)});
			}
			player.play();
		}
	}
	m3u.getFilename = function(i) {
		var parts = files[i].split('/');
                return parts[parts.length-1];
	}
	m3u.getFeedname = function(i) {
                var parts = files[i].split('/');
		if (parts.length < 2) return false;
                return parts[parts.length-2];
        }
	m3u.drawOne = function(i, current) {

		var url = files[i];
                if (url) {
	                var name = this.getFilename(i);
//                      url = parts[0];
//                      for (var j=1; j<parts.length-1;j++) {
//                      	url += '/'+escape(parts[j]);
//                      }
                        var type = this.testURL(url);
                        if(type) {
                        	return this.getPlayerText(url, name, type, i, current);
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
                	text += '<li>'+this.drawOne(i, false)+'</li>';
                }
		text += '</ul>';
		return text;
	}
	m3u.getPlayerText = function(url, name, type, id, autoload) {
		var tag = (type.substring(0,5).toLowerCase() == 'video') ? 'video' : 'audio';
		var text;
		text = '<'+tag+' id="media_'+id+'" controls="controls" onerror="m3u.error(event);">';
		var  autoload = autoload ? 'auto' : 'metadata';
		text += '<source src="'+url+'" type="'+type+'" ';
		text += 'preload="'+autoload+'" /></'+tag+'>';
		text += '<label><a href="'+url+'" target="_blank">';
		text += name;
		text += '</a></label>';
		return text;
	}
	m3u.testAllURLs = function(url) {
		for (var i=0; i<files.length;i++) {
			this.testURL(files[i]);
		}
	}
	m3u.error = function(e) {
		this.lastError = e;
		console.log(e);
		switch (e.target.error.code) {
			case e.target.error.MEDIA_ERR_ABORTED:
				// kein Fehler
			break;
			case e.target.error.MEDIA_ERR_NETWORK:
				alert('A network error caused the video download to fail part-way.');
			break;
			case e.target.error.MEDIA_ERR_DECODE:
				alert('The video playback was aborted due to a corruption problem or because the video used features your browser did not support.');
			break;
			case e.target.error.MEDIA_ERR_SRC_NOT_SUPPORTED:
				alert('The video could not be loaded, either because the server or network failed or because the format is not supported.');
			break;
			default:
				alert('An unknown error occurred.');
			break;
		}
	}
	m3u.testURL = function(url) {
		var http = new XMLHttpRequest();
		http.open('HEAD', url, false);
		http.send();
		if (http.status==404) return false;
		this.dates[url] = http.getResponseHeader('Last-Modified');
		this.sizes[url] = http.getResponseHeader('Content-Length');
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
