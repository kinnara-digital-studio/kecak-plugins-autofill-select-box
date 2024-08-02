<div class="form-cell" ${elementMetaData!}>
	<link rel="stylesheet" href="${request.contextPath}/bower_components/select2/dist/css/select2.min.css" />

    <script type="text/javascript" src="${request.contextPath}/bower_components/select2/dist/js/select2.min.js"></script>
    <script type="text/javascript" src="${request.contextPath}/plugin/${className}/js/jquery.autofillselectbox.js"></script>
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
        <select class="js-select2" id="${elementId}" name="${elementParamName!}" <#if error??>class="form-error-cell"</#if> <#if element.properties.readonly! == 'true'> disabled </#if>>
            <#if element.properties.lazyLoading! != 'true' >
                <#list options! as option>
                    <option value="${option.value!?html}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if>>${option.label!?html}</option>
                </#list>
            <#else>
                <#list options! as option>
                    <#if values?? && values?seq_contains(option.value!) || option.value == ''>
                        <option value="${option.value!?html}" grouping="${option.grouping!?html}" <#if values?? && values?seq_contains(option.value!)>selected</#if>>${option.label!?html}</option>
                    </#if>
                </#list>
            </#if>
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
                <#--
                $('#${elementId!}.js-select2').autofillSelectBox({
                    contextPath : '${request.contextPath}',
                    appId : '${appId!}',
                    appVersion : '${appVersion!}',
                    form : '${formDefId!}',
                    className : '${className}',
                    messages : {
                       errorLoading : '${element.properties.messageErrorLoading!}',
                       loadingMore : '${element.properties.messageLoadingMore!}',
                       noResults : '${element.properties.messageNoResults!}',
                       searching : '${element.properties.messageSearching!}'
                    },
                    lazyLoading : ${(element.properties.lazyLoading! == 'true')?string('true', 'false')}
                });
                -->

                let $selectBox = $('#${elementId!}.js-select2')
                        .select2({
                            //placeholder: '${element.properties.placeholder!}',
                            width : '${width!}',
                            theme : 'classic',
                            language : {
                               errorLoading: () => '${element.properties.messageErrorLoading!}',
                               loadingMore: () => '${element.properties.messageLoadingMore!}',
                               noResults: () => '${element.properties.messageNoResults!}',
                               searching: () => '${element.properties.messageSearching!}'
                            }

                            <#if element.properties.lazyLoading! == 'true' >
                                ,ajax: {
                                    url: '${request.contextPath}/web/json/app/${appId!}/${appVersion!}/plugin/${className}/service',
                                    delay : 500,
                                    dataType: 'json',
                                    data : function(params) {
                                        return {
                                            search: params.term,
                                            appId : '${appId!}',
                                            appVersion : '${appVersion!}',
                                            formDefId : '${formDefId!}',
                                            fieldId : '${element.properties.id!}',
                                            <#if element.properties.controlField! != '' >
                                                grouping : FormUtil.getValue('${element.properties.controlField!}'),
                                            </#if>
                                            page : params.page || 1
                                        };
                                    }
                                }
                            </#if>
                        })

                        <#if !includeMetaData>
                            .autofillSelectBox({
                                contextPath : '${request.contextPath}',
                                appId : '${appId!}',
                                appVersion : '${appVersion!}',
                                elementId : '${element.properties.id!}',
                                controlField : '${element.properties.controlField!}',
                                targetFieldAsReadonly: ${(element.properties.targetFieldAsReadonly! == 'true')?string('true', 'false')},
                                lazyMapping : ${(element.properties.lazyMapping! != 'true')?string('true', 'false')},
                                requestBody : ${requestBody!},
                                className : '${className}',
                                assets : {
                                    $loadingImage: $('img#${elementId!}_loading')
                                },
                                targets : ${fieldsMappingJson!}
                            })
                        </#if>
                        ;

                <#if !includeMetaData && element.properties.triggerOnPageLoad! == 'true'>
                    $selectBox.change();
                </#if>

                <#if (element.properties.readonly! == 'true') >
                    $('#${elementId!} option:not(:selected)').attr('disabled', true);
                    $('#${elementId!}.js-select2').attr("disabled", true).trigger("change");
                </#if>
            });
        </script>
    </#if>
</div>
