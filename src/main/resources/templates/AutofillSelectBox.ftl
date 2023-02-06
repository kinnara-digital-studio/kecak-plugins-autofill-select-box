<div class="form-cell" ${elementMetaData!}>
	<script type="text/javascript" src="${request.contextPath}/node_modules/select2/dist/js/select2.full.min.js"></script>
    <link rel="stylesheet" href="${request.contextPath}/node_modules/select2/dist/css/select2.min.css">
    <script type="text/javascript" src="${request.contextPath}/js/select2.kecak.js"></script>

    <#-- <script type="text/javascript" src="${request.contextPath}/plugin/${className}/js/jquery.autofillselectbox.js"></script> -->
    <script type="text/javascript" src="${request.contextPath}/js/json/formUtil.js"></script>
	
	<#assign elementId = elementParamName + element.properties.elementUniqueKey>
	
    <label class="label">${element.properties.label} <span class="form-cell-validator">${decoration}</span><#if error??> <span class="form-error-message">${error}</span></#if></label>

    <#if includeMetaData>
        <span class="form-floating-label">${fieldType}</span>
    </#if>

    <#if (element.properties.readonly! == 'true' && element.properties.readonlyLabel! == 'true') >
        <div class="form-cell-value">
            <#list options! as option>
                <#if values?? && values?seq_contains(option.value!)>
                    <label class="readonly_label">
                        <span>${option.label!?html}</span>
                        <input id="${elementParamName!}" name="${elementParamName!}" type="hidden" value="${option.value!?html}" />
                    </label>
                </#if>
            </#list>
        </div>
        <div style="clear:both;"></div>
    <#else>
        <select class="js-select2" <#if element.properties.readonly! != 'true'>id="${elementParamName!}${element.properties.elementUniqueKey!}"</#if> name="${elementParamName!}" <#if element.properties.size?? && element.properties.size != ''> style="width:${element.properties.size!}%"</#if> <#if error??>class="form-error-cell"</#if> <#if element.properties.readonly! == 'true'> disabled </#if>>
            <#list options! as option>
                <#if values?? && values?seq_contains(option.value!) || option.value == ''>
                    <option value="${option.value!?html}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if>>${option.label!?html}</option>
                </#if>
            </#list>
        </select>
    </#if>
    <#if (element.properties.readonly! != 'true') >
        <img id="${elementId}_loading" src="${request.contextPath}/plugin/${className}/images/spin.gif" height="24" width="24" style="vertical-align: middle; display: none;">
    </#if>

    <#if element.properties.controlField?? && element.properties.controlField! != "" && !(element.properties.readonly! == 'true' && element.properties.readonlyLabel! == 'true') >
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
    
    <#if element.properties.readonly! != 'true' >
        <script type="text/javascript">
            $(document).ready(function(){
                let $autofillSelectbox = $('#${elementId!}.js-select2').kecakSelect2({
                    //placeholder: '${element.properties.placeholder!}',
                    width : '100%',
                    language : {
                       errorLoading: () => '${element.properties.messageErrorLoading!}',
                       loadingMore: () => '${element.properties.messageLoadingMore!}',
                       noResults: () => '${element.properties.messageNoResults!}',
                       searching: () => '${element.properties.messageSearching!}'
                    },
                    ajax: {
                        url: '${request.contextPath}/web/json/app/${appId!}/${appVersion!}/plugin/${className}/service',
                        delay : 500,
                        dataType: 'json',
                        data : function(params) {
                            return {
                                search: params.term,
                                formDefId : '${formDefId!}',
                                fieldId : '${element.properties.id!}',
                                <#if element.properties.controlField! != '' >
                                    grouping : FormUtil.getValue('${element.properties.controlField!}'),
                                </#if>
                                page : params.page || 1,
                                nonce: '${nonce}'
                            };
                        }
                    }
                });

                <#-- fetch preselected data -->
                let values = '${values?join(";")}';
                if(values) {
                    $autofillSelectbox.trigger({
                        type : 'change',
                        params : {
                            value : values
                        }
                    });
                }

                let prefix = "${elementId}".replace(/${element.properties.id!}${element.properties.elementUniqueKey!}$/, "");

                const TIMEOUT = 100;
                $('#${elementId}').change(() => setTimeout(trigger_${elementId}, TIMEOUT));

                <#if element.properties.triggerOnPageLoad! == 'true'>
                    $('#${elementId}').change();
                </#if>

                <#if element.properties.targetFieldAsReadonly! == 'true'>
                    <#list fieldsMapping?keys! as field>
                        {
                            let $selector = FormUtil.getField('${field!}');
                            $selector.each(function() {
                                $(this).attr('readonly', 'readonly');
                                $(this).attr('disabled', 'disabled');
                            });
                        }
                    </#list>
                </#if>

                function trigger_${elementId}() {
                    <#if includeMetaData == false || requestBody?? >
                        let primaryKey = $('#${elementId}').val();
                        let url = '${request.contextPath}/web/json/app/${appId!}/${appVersion!}/plugin/${className}/service';

                        let jsonData = {
                            appId : '${appId!}',
                            appVersion : '${appVersion!}',
                            ${keyField} : primaryKey,
                            ...${requestBody!}
                        };

                        if(!(jsonData['FORM_ID'] && jsonData['FIELD_ID']))
                            return;

                        jsonData.requestParameter = new Object();

                        <#-- BETA -->
                        // set input fields as request parameter
                        let prefix = '${element.properties.customParameterName!}'.replace(/${element.properties.id}$/, '');
                        let patternPrefix = new RegExp('^' + prefix);

                        $('img#${elementId!}_loading').show();
                        $('input[name^="' + prefix + '"]').each(function() {
                            let name = $(this).attr('name');
                            let value = $(this).val();
                            if(name) {
                                jsonData.requestParameter[name.replace(patternPrefix, '')] = value;
                            }
                        });

                        $.ajax({
                            url: url,
                            type : 'POST',
                            headers : { 'Content-Type' : 'application/json' },
                            data : JSON.stringify(jsonData)
                        })
                        .done(function(data) {
                            $('img#${elementId!}_loading').hide();

                            let pair = {}; // formField : resultData
                            <#list fieldsMapping?keys! as formField>
                                <#assign resultDataField = fieldsMapping[formField]>
                                pair['${formField!}'] = data.${resultDataField!};
                            </#list>

                            if(!data && data.length == 0) {
                                return;
                            }

                            for(let fieldId in pair) {
                                let value = pair[fieldId];
                                autofill(fieldId, value);
                            }

                            function autofill(fieldId, value) {
                                let $selector = FormUtil.getField(fieldId);

                                if($selector.is(':checkbox, :radio')) {
                                    $selector.each(function() {
                                        let multivalue = value.split(/;/);
                                        $(this).prop('checked', multivalue.indexOf($(this).val()) >= 0);
                                    });
                                } else if($selector.is('select')) {
                                    $selector.val(values.split(/;/));
                                    $selector.trigger({
                                         type: "change",
                                         params: {
                                             value : value
                                         }
                                     });
                                } else {
                                    $selector.each(function() {
                                        $(this).val(value);
                                        $(this).trigger("change");
                                    });
                                }
                            }
                        })
                        .fail(function() {
                            $('img#${elementId!}_loading').hide();
                            <#list element.properties.autofillFields! as field>
                                $("[name='" + prefix + "${field.formField!}']").val("");
                            </#list>
                        });
                    </#if>
                }

                <#if (element.properties.readonly! == 'true') >
                    $('#${elementId!} option:not(:selected)').attr('disabled', true);
                    $('#${elementId!}.js-select2').attr("disabled", true).trigger("change");
                </#if>
            });
        </script>
    </#if>
</div>
