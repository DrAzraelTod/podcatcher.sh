var m3u = function(targetID, m3uPath, sequential) {
	this.files;
	this.current_file = 0;

	var parse = function(data, status) {
		files = data.split('\n');
		var target = document.getElementById(targetID);
		//target.children().remove();
		var text = '<ul>';
		for (var i=0;i<files.length;i++) {
			var url = files[i];
			if (url) {
				var parts = url.split('/');
		                var name = parts[parts.length-1];
//				url = parts[0];
//				for (var j=1; j<parts.length-1;j++) {
//					url += '/'+escape(parts[j]);
//				}
				if(!fileRemoved(url)) {
					text += getTagsText(url, name);
				} else { console.log(url); }
			}
		}
		text += '</ul>';
		target.innerHTML = text;

	}
	var getTagsText = function(url, name) {
		var text = '<li></label><audio controls="controls"><source src="';
		text += url;
		text += '" type="audio/ogg" preload="metadata"></audio><label>';
		text += '<a href="'+url+'" target="_blank">';
		text += name;
		text += '</a></label></li>';
		return text;
	}
	function fileRemoved(url) {
		var http = new XMLHttpRequest();
		http.open('HEAD', url, false);
		http.send();
		return http.status==404;
	}
//	var request = jQuery.ajax('relative.m3u', {'success' : parse});
	var request = new XMLHttpRequest();
	request.open('GET',m3uPath, false)
	request.send();
	if (request.status == 200) {
		parse(request.responseText, request.status);
	}
}
