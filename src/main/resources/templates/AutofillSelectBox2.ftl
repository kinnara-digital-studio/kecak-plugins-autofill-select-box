<div class="form-cell" ${elementMetaData!}>

    <!-- ================= SELECT2 ================= -->
    <script type="text/javascript" src="${request.contextPath}/node_modules/select2/dist/js/select2.full.min.js"></script>
    <link rel="stylesheet" href="${request.contextPath}/node_modules/select2/dist/css/select2.min.css">
    <script type="text/javascript" src="${request.contextPath}/js/select2.kecak.js"></script>

    <!-- ================= CONTROLLER ================= -->
    <script type="text/javascript" src="${request.contextPath}/plugin/${className}/js/autofill-selectbox-crud.js"></script>

    <label class="label"
           for="${elementParamName!}${element.properties.elementUniqueKey!}"
           field-tooltip="${elementParamName!}">
        ${element.properties.label}
        <span class="form-cell-validator">${decoration}</span>
        <#if error??>
            <span class="form-error-message">${error}</span>
        </#if>
    </label>

    <#if (element.properties.readonly! == 'true' && element.properties.readonlyLabel! == 'true')>

        <div class="form-cell-value">
            <#list options as option>
                <#if values?? && values?seq_contains(option.value!)>
                    <label class="readonly_label">
                        <span>${option.label!?html}</span>
                    </label>
                </#if>
            </#list>
        </div>

    <#else>

        <style>
            .select2-container { margin-bottom: 0 !important; }
            .select2-search--dropdown .select2-search__field { float:none !important; }
        </style>

        <div style="display:flex; align-items:center; gap:5px; margin-bottom:18px;">

            <select class="js-select2"
                    id="${elementParamName!}${element.properties.elementUniqueKey!}"
                    name="${elementParamName!}"
                    <#if element.properties.size??>
                        style="width:${element.properties.size!}%"
                    </#if>
                    <#if element.properties.multiple! == 'true'>
                        multiple="multiple"
                    </#if>
                    <#if element.properties.readonly! == 'true'>
                        disabled
                    </#if>>


                <#if enableCrud?? && enableCrud == true>
                    <option value="__add_data__">+ Add Data</option>
                </#if>

                <#if element.properties.lazyLoading! != 'true'>
                    <#list options as option>
                        <option value="${option.value!?html}"
                                data-id="${option.plainValue!}"
                                <#if values?? && values?seq_contains(option.value!)>
                                    selected
                                </#if>>
                            ${option.label!?html}
                        </option>
                    </#list>
                <#else>
                    <#list options! as option>
                        <#if values?? && values?seq_contains(option.value!)>
                            <option value="${option.value!?html}" selected>
                                ${option.label!?html}
                            </option>
                        </#if>
                    </#list>
                </#if>

            </select>

            <#if addEdit?? && addEdit == true>
                <button type="button"
                        id="${elementParamName!}_editBtn"
                        style="display:none;"
                        class="btn btn-warning">
                    <i class="fa fa-long-arrow-right"></i>
                </button>
            </#if>

            <#if addDelete?? && addDelete == true>
                <button type="button"
                        id="${elementParamName!}_deleteBtn"
                        style="display:none;"
                        class="btn btn-danger">
                    <i class="fa fa-trash"></i>
                </button>
            </#if>

            <img id="${elementParamName!}${element.properties.elementUniqueKey!}_loading"
                 src="${request.contextPath}/plugin/${className}/images/spin.gif"
                 height="24"
                 width="24"
                 style="display:none;">

        </div>

    </#if>


    <!-- ================= INIT CONTROLLER ================= -->
    <script type="text/javascript">
    $(document).ready(function(){

        const $select = $('select#${elementParamName!}${element.properties.elementUniqueKey!}.js-select2');

        AutofillSelectBoxCrudController.init($select, {

            /* ================= BASIC ================= */
            paramName : '${elementParamName!}',
            contextPath : '${request.contextPath}',
            appId : '${appId!}',
            appVersion : '${appVersion!}',
            className : '${className}',

            /* ================= CRUD ================= */
            enableCrud : ${(enableCrud!false)?string('true','false')},
            addEmptyOption : ${(addEmptyOption!false)?string('true','false')},
            crudFormDefId : '${crudFormDefId!}',
            addEdit : ${(addEdit!false)?string('true','false')},
            addDelete : ${(addDelete!false)?string('true','false')},
            crudFormJson : '${crudFormJson!?js_string}',
            crudFormNonce : '${crudFormNonce!?js_string}',
            labelColumn: '${labelColumn!}',
            elementUniqueKey: '${element.properties.elementUniqueKey!}',

            /* ================= AUTOFILL ================= */
            targets : ${fieldsMappingJson!},
            requestBody : ${requestBody!},
            targetFieldAsReadonly : ${(element.properties.targetFieldAsReadonly! == 'true')?string('true','false')},

            /* ================= ASSETS ================= */
            assets : {
                $loadingImage : $('img#${elementParamName!}${element.properties.elementUniqueKey!}_loading')
            },

            /* ================= OPTIONS ================= */
            triggerOnLoad :
                ${(element.properties.triggerOnPageLoad! == 'true')?string('true','false')}

        });
        

    });
    </script>

</div>
