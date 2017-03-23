<div class="form-cell" ${elementMetaData!}>
	<link rel="stylesheet" href="${request.contextPath}/plugin/${className}/css/chosen.min.css">
	<script src="${request.contextPath}/plugin/${className}/js/chosen.jquery.min.js" type="text/javascript"></script>
	
	<#assign elementId = elementParamName + element.properties.elementUniqueKey>
	
    <label class="label">${element.properties.label} <span class="form-cell-validator">${decoration}</span><#if error??> <span class="form-error-message">${error}</span></#if></label>
    <#if (element.properties.readonly! == 'true' && element.properties.readonlyLabel! == 'true') >
        <div class="form-cell-value">
            <#list options as option>
                <#if values?? && values?seq_contains(option.value!)>
                    <label class="readonly_label">
                        <span>${option.label!?html}</span>
                    </label>
                </#if>
            </#list>
        </div>
        <div style="clear:both;"></div>
    <#else>
        <select class="chosen-select" <#if element.properties.readonly! != 'true'>id="${elementId}"</#if> name="${elementParamName!}" <#if element.properties.multiple! == 'true'>multiple</#if> <#if error??>class="form-error-cell"</#if> <#if element.properties.readonly! == 'true'> disabled </#if>>
            <#list options as option>
                <option value="${option.value!?html}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if> <#if element.properties.readonly! == 'true'>disabled</#if>>${option.label!?html}</option>
            </#list>
        </select>
        <img id="${elementId}_loading" src="${request.contextPath}/plugin/${className}/images/ellipsis.gif" height="25" width="25" style="vertical-align: middle; display: none;">
    </#if>
    <#if element.properties.readonly! == 'true'>    
        <#list values as value>
            <input type="hidden" id="${elementParamName!}" name="${elementParamName!}" value="${value?html}" />
        </#list>
    </#if>

    <#if (element.properties.controlField?? && element.properties.controlField! != "" && !(element.properties.readonly! == 'true' && element.properties.readonlyLabel! == 'true')) >
        <script type="text/javascript" src="${request.contextPath}/plugin/org.joget.apps.form.lib.SelectBox/js/jquery.dynamicoptions.js"></script>
        <script type="text/javascript">
            $(document).ready(function(){
                $("#${elementId}").dynamicOptions({
                    controlField : "${element.properties.controlFieldParamName!}",
                    paramName : "${elementParamName!}",
                    type : "selectbox",
                    readonly : "${element.properties.readonly!}",
                    nonce : "${element.properties.nonce!}",
                    binderData : "${element.properties.binderData!}",
                    appId : "${element.properties.appId!}",
                    appVersion : "${element.properties.appVersion!}",
                    contextPath : "${request.contextPath}"
                });
            });
        </script>
    </#if>
    
    <script type="text/javascript">
    	$(document).ready(function(){
	        var config = {
			  '#${elementId}.chosen-select'           : {},
			  '#${elementId}.chosen-select-deselect'  : {allow_single_deselect:true},
			  '#${elementId}.chosen-select-no-single' : {disable_search_threshold:10},
			  '#${elementId}.chosen-select-no-results': {no_results_text:'Oops, nothing found!'},
			  '#${elementId}.chosen-select-width'     : {width:"95%"}
			}
			
			for (var selector in config) {
			  $(selector).chosen({width : "${element.properties.size!}%"});
			}
			
			var prefix = "${elementId}".replace(/${element.properties.id!}${element.properties.elementUniqueKey!}$/, "");
			
			<#if values??>
				// $('#${elementId}').ready(trigger_${elementId});
			</#if>
    		$('#${elementId}').change(trigger_${elementId});
    		
    		function trigger_${elementId}() {
    			var primaryKey = $(this).val();
    			var url = "${request.contextPath}/web/json/plugin/${className}/service?${keyField}=" + primaryKey;
    			
    			$('img#${elementId!}_loading').show();
    			$.ajax({
		            url: url,
		            type : 'POST',
		            headers : { 'Content-Type' : 'application/json' },
		            data : JSON.stringify({ "autofillLoadBinder" : ${autofillLoadBinder!}, "autofillForm" : ${autofillForm!}})
		        })
				.done(function(data) {
					$('img#${elementId!}_loading').hide();
					
		         	for(var i in data) {
		         		if(data[i]) {
				         <#list fieldsMapping?keys! as field>
				         	if(data[i].${fieldsMapping[field]!}) {
					         	<#assign fieldType = fieldTypes[field!]!>
					         	<#if fieldType! == 'RADIOS' >
				         			$("input[name$='" + prefix + "${field!}']").each(function() {
				         				$(this).prop('checked', $(this).val() == data[i].${fieldsMapping[field]!});
				         			});
				         		<#elseif fieldType! == 'CHECK_BOXES'>
				         			$("input[name$='" + prefix + "${field!}']").each(function() {
				         				var multivalue = data[i].${fieldsMapping[field]!}.split(/;/);
				         				$(this).prop('checked', multivalue.indexOf($(this).val()) >= 0);
				         			});
				         		<#elseif fieldType! == 'GRIDS'>			         			
				         			$("div.grid[name$='" + prefix + "${field!}']").each(function() {
				         				<#-- remove previous grid row -->
					         			$(this).find('tr.grid-row').each(function() {
					         				$(this).remove();
					         			});
				         			
				         				try {
				         					var functionAdd = window[$(this).prop('id') + '_add'];
				         					if(typeof functionAdd == 'function') {
						         				var gridData = JSON.parse(data[i].${fieldsMapping[field]!});
						         				for(var j in gridData) {
						         					functionAdd({result : JSON.stringify(gridData[j])});
						         				}
						         			}
					         			} catch (e) { }
					         		});
				         		<#elseif fieldType! == 'SELECT_BOXES'>
				         			$("select[name$='" + prefix + "${field!}']").each(function() {
				    					$(this).val(data[i].${fieldsMapping[field]!}.split(/;/));
				    					$(this).trigger("chosen:updated");
				    				});
				    			<#else>
				    				$("[name$='" + prefix + "${field!}']").each(function() {
				    					$(this).val(data[i].${fieldsMapping[field]!});
				    				});
				    			</#if>
				    		}	
				    	</#list>
				    	}
			    	}
		        })
				.fail(function() {
					$('img#${elementId!}_loading').hide();
		         	<#list element.properties.autofillFields! as field>
			    		$("[name$='" + prefix + "${field.formField!}']").val("");	
			    	</#list>
		    	});
    		}
		});
    </script>
</div>
