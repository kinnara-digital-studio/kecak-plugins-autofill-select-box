/**
 * Autofill SelectBox CRUD Controller
 */
(function () {

    if (window.AutofillSelectBoxCrudController) return;

    window.AutofillSelectBoxCrudController = {

        /* ================= STATE ================= */
        select: null,
        config: null,

        /* ================= INIT ================= */
        init: function ($select, config) {

            if (!$select || !$select.length) return;

            this.select = $select;
            this.config = config || {};

            this.prepareCrudOption();
            this.initSelect2();
            this.bindEvents();
            this.prepareAutofill();
            this.registerCrudCallbacks();

            if (this.config.triggerOnLoad) {
                setTimeout(() => this.select.trigger("change"), 800);
            }
        },

        /* ================= SELECT2 ================= */
        initSelect2: function () {
            this.select.kecakSelect2({
                dropdownAutoWidth: true,
                width: this.select.css("width"),
                theme: "default"
            });
        },

        /* ================= ADD DATA OPTION POSITION ================= */
        prepareCrudOption: function () {

            const $select = this.select;

            if (this.config.enableCrud){
                $select.find("option[value='__add_data__']").remove();

                if (this.config.addEmptyOption) {
                    let $empty = $select.find("option[value='']").first();

                    if ($empty.length) {
                    $('<option value="__add_data__">+ Add Data</option>')
                            .insertAfter($empty);
                    } else {
                        $select.prepend('<option value="__add_data__">+ Add Data</option>');
                    }

                } else {
                    $select.prepend('<option value="__add_data__">+ Add Data</option>');
                }

                $select.trigger('change.select2');
            }
        },


        /* ================= EVENTS ================= */
        bindEvents: function () {
            this.select.on("change", () => {
                const value = this.select.val();

                if (value === "__add_data__") {
                    this.select.val(null).trigger("change.select2");
                    this.openPopup("add");
                    return;
                }

                this.toggleButtons(value);
                this.handleAutofill(value);
            });

            if (this.config.addDelete) {
                $("#" + this.config.paramName + "_deleteBtn")
                    .off("click")
                    .on("click", () => this.deleteData());
            }

            if (this.config.addEdit) {
                $("#" + this.config.paramName + "_editBtn")
                    .off("click")
                    .on("click", () => this.openPopup("edit"));
            }
        },

        /* ================= BUTTON VISIBILITY ================= */
        toggleButtons: function (value) {

            const $edit = $("#" + this.config.paramName + "_editBtn");
            const $delete = $("#" + this.config.paramName + "_deleteBtn");

            if (value && value !== "__add_data__") {
                if (this.config.addEdit) $edit.css("display", "flex");
                if (this.config.addDelete) $delete.css("display", "flex");
            } else {
                $edit.hide();
                $delete.hide();
            }
        },

        /* ================= AUTOFILL SETUP ================= */
        prepareAutofill: function () {

            if (!this.config.targets) return;

            if (this.config.targetFieldAsReadonly) {

                for (const formField in this.config.targets) {

                    const $selector = FormUtil.getField(formField);

                    $selector.each(function () {
                        $(this).attr("readonly", "readonly")
                               .attr("disabled", "disabled");
                    });

                    const shadow =
                        '<input type="hidden" id="' +
                        $selector.attr("id") +
                        '_shadow" name="' +
                        $selector.attr("name") +
                        '" />';

                    $selector.parent().append(shadow);
                }
            }
        },

        /* ================= AUTOFILL CORE ================= */
        handleAutofill: function (primaryKey) {

            if (!this.config.targets) return;

            if (!primaryKey || primaryKey === "__add_data__") {
                this.clearAutofill();
                return;
            }

            const url = this.config.contextPath + "/web/json/app/" + this.config.appId + "/" + this.config.appVersion + "/plugin/" + this.config.className + "/service";

            const payload = {
                appId: this.config.appId,
                appVersion: this.config.appVersion,
                id: primaryKey,
                ...this.config.requestBody,
                requestParameter: {}
            };

            this.config.assets?.$loadingImage?.show();

            $.ajax({
                url: url,
                type: "POST",
                headers: { "Content-Type": "application/json" },
                data: JSON.stringify(payload)
            })
            .done((data) => {
                this.applyAutofill(data);
            })
            .always(() => {
                this.config.assets?.$loadingImage?.hide();
            });
        },

        /* ================= CLEAR TARGETS ================= */
        clearAutofill: function () {

            for (let formField in this.config.targets) {

                const $selectors = FormUtil.getField(formField);

                $selectors.each(function () {

                    const $selector = $(this);

                    if ($selector.is(":checkbox, :radio")) {
                        $selector.prop("checked", false);
                    } else if ($selector.is("select")) {
                        $selector.val([]).trigger("change");
                        if (typeof $selector.chosen === "function") {
                            $selector.trigger("chosen:updated");
                        }
                    } else {
                        $selector.val("").trigger("change");
                    }
                });
            }
        },

        /* ================= APPLY RESULT ================= */
        applyAutofill: function (data) {

            for (let formField in this.config.targets) {

                const $selectors = FormUtil.getField(formField);
                const targetField = this.config.targets[formField];

                const resultField = targetField.replace(/\[\d+\]/g, "");
                const resultIndex = parseInt(
                    targetField.replace(/.+\[(?=\d)|\].*/g, "")
                );

                const resultValue = data[resultField];
                const value = isNaN(resultIndex)
                    ? resultValue
                    : resultValue?.split(";")[resultIndex];

                if (value || value === "") {

                    $selectors.each(function () {

                        const $selector = $(this);

                        if ($selector.is(":checkbox, :radio")) {

                            const multivalue = value.split(";");
                            $selector.prop(
                                "checked",
                                multivalue.indexOf($selector.val()) >= 0
                            );

                        } else if ($selector.is("select")) {

                            const multivalue = value.split(";");
                            $selector.val(multivalue).trigger("change");
                            $selector.trigger("chosen:updated");

                        } else {

                            $selector.val(value).trigger("change");
                        }
                    });
                }
            }
        },

        /* ================= DELETE ================= */
        deleteData: function () {

            const selectedId = this.select.val();
            if (!selectedId) return;

            if (!confirm("Are you sure you want to delete this data?")) return;

            $.ajax({
                url:
                    this.config.contextPath +
                    "/web/json/data/app/" +
                    this.config.appId +
                    "/form/" +
                    this.config.crudFormDefId +
                    "/" +
                    selectedId,
                type: "DELETE",
                success: () => {
                    this.select
                        .find("option[value='" + selectedId + "']")
                        .remove();

                    this.select.val(null).trigger("change");
                    alert("Data deleted successfully");
                }
            });
        },

        /* ================= POPUP ================= */
        openPopup: function (type) {

            const isEdit = type === "edit";
            const frameId = "formPopup_" + this.config.paramName;

            if (window.JPopup && !isEdit) {
                JPopup.create(
                    frameId,
                    "Add Data",
                    "80%",
                    "80%"
                );
            }

            let url =
                this.config.contextPath +
                "/web/app/" +
                this.config.appId +
                "/" +
                this.config.appVersion +
                "/form/embed?_submitButtonLabel=" +
                (isEdit ? "Save" : "Submit");

            if (typeof UI !== "undefined" && typeof UI.userviewThemeParams === "function") {
                url += UI.userviewThemeParams();
            } else if (window.ConnectionManager && window.ConnectionManager.tokenName) {
                url +=
                    "&" +
                    window.ConnectionManager.tokenName +
                    "=" +
                    window.ConnectionManager.tokenValue;
            }

            let params = {
                _json: this.config.crudFormJson,
                _callback:
                    this.config.paramName +
                    (isEdit ? "_editDataCallback" : "_addDataCallback"),
                _nonce: this.config.crudFormNonce,
                _setting: "{}"
            };

            if (isEdit) {

                const $select = this.select;
                let $selectedOption = $select.find(":selected");
                let encryptedId = $select.val();
                let plainId = $selectedOption.attr("data-id");

                if (!plainId) plainId = encryptedId;
                if (!plainId || plainId === "__add_data__") return;

                params.id = plainId;
            }

            if (window.JPopup) {
                JPopup.show(frameId, url, params, "", "80%", "80%");
            }
        },


        /* ================= REGISTER CALLBACK ================= */
        registerCrudCallbacks: function () {

            const self = this;
            const selectId =
                "select#" +
                this.config.paramName +
                this.config.elementUniqueKey +
                ".js-select2";

            /* ===== ADD CALLBACK ===== */
            window[this.config.paramName + "_addDataCallback"] = function (args) {

                let result =
                    typeof args.result === "string"
                        ? JSON.parse(args.result)
                        : args.result;

                let newId = result.id || result.ID;

                let labelColumn = self.config.labelColumn;
                let newLabel =
                    labelColumn && result[labelColumn]
                        ? result[labelColumn]
                        : newId;

                let newOption = new Option(newLabel, newId, true, true);
                self.select.append(newOption);

                self.select.trigger("change");

                if (window.JPopup) {
                    JPopup.hide("formPopup_" + self.config.paramName);
                }
            };

            /* ===== EDIT CALLBACK ===== */
            window[self.config.paramName + "_editDataCallback"] = function (args) {

                let result =
                    typeof args.result === "string"
                        ? JSON.parse(args.result)
                        : args.result;

                let editedId = result.id || result.ID;

                let labelColumn = self.config.labelColumn;
                let newLabel =
                    labelColumn && result[labelColumn]
                        ? result[labelColumn]
                        : editedId;

                self.select.find("option[value='" + editedId + "']").remove();

                let newOption = new Option(newLabel, editedId, true, true);

                self.select.append(newOption);

                self.select.trigger({
                    type: 'select2:select',
                    params: {
                        data: { id: editedId, text: newLabel }
                    }
                });

                self.select.val(editedId).trigger("change");

                if (window.JPopup) {
                    JPopup.hide("formPopup_" + self.config.paramName);
                }
            };
        },

    };

})();
