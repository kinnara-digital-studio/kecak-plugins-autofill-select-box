/**
 * Autofill SelectBox CRUD Controller
 */
(function () {

    if (window.AutofillSelectBoxCrudController) return;

    function AutofillSelectBoxCrudInstance($select, config) {
        this.select = $select;
        this.config = config || {};

        this.prepareCrudOption();
        this.bindEvents();
        this.registerCrudCallbacks();

        this.toggleButtons(this.getValue());
    }

    AutofillSelectBoxCrudInstance.prototype = {

        getValue: function () {
            let val = this.select.val();
            if (!val || (Array.isArray(val) && val.length === 0)) {
                let $opt = this.select.find("option:selected");
                if ($opt.length && $opt.val()) {
                    val = $opt.val();
                } else if (this.config.paramName) {
                    let hiddenVal = $("#" + this.config.paramName + "_hidden").val() || $("#" + this.config.paramName).val();
                    if (hiddenVal) val = hiddenVal;
                }
            }
            return val;
        },

        /* ================= ADD DATA OPTION POSITION ================= */
        prepareCrudOption: function () {
            const $select = this.select;

            if (this.config.enableCrud && !this.config.readonly){
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

        executeEnhancement: function ($trigger) {
            if (typeof this.config.javascriptEnhancementOnFormLoad === 'function') {
                this.config.javascriptEnhancementOnFormLoad(this.select, $trigger);
            }
        },

        /* ================= EVENTS ================= */
        bindEvents: function () {
            const self = this;

            this.select.on("change", function () {
                const value = self.select.val();
                const isAddData = value === "__add_data__" || (Array.isArray(value) && value.indexOf("__add_data__") !== -1);

                if (isAddData) {
                    self.select.val(null).trigger("change.select2");
                    self.executeEnhancement(self.select);
                    self.openPopup("add");
                    return;
                }
                self.toggleButtons(value);
            });

            if (this.config.readonly) {
                const $viewBtn = $("#" + this.config.paramName + "_viewBtn");
                $viewBtn
                    .off("click")
                    .on("click", function () {
                        self.executeEnhancement($viewBtn);
                        self.openPopup("view");
                    });
            } else {
                if (this.config.addDelete) {
                    $("#" + this.config.paramName + "_deleteBtn")
                        .off("click")
                        .on("click", function () {
                            self.deleteData();
                        });
                }

                if (this.config.addEdit) {
                    const $editBtn = $("#" + this.config.paramName + "_editBtn");
                    $editBtn
                        .off("click")
                        .on("click", function () {
                            self.executeEnhancement($editBtn);
                            self.openPopup("edit");
                        });
                }
            }
        },

        /* ================= BUTTON VISIBILITY ================= */
        toggleButtons: function (value) {
            if (value === undefined || value === null || value === "") {
                value = this.getValue();
            }
            const $edit = $("#" + this.config.paramName + "_editBtn");
            const $delete = $("#" + this.config.paramName + "_deleteBtn");
            const $view = $("#" + this.config.paramName + "_viewBtn");
            const isAddData = value === "__add_data__" || (Array.isArray(value) && value.indexOf("__add_data__") !== -1);

            if (value && !isAddData) {
                if (this.config.readonly) {
                    $view.css("display", "flex");
                } else {
                    if (this.config.addEdit) $edit.css("display", "flex");
                    if (this.config.addDelete) $delete.css("display", "flex");
                }
            } else {
                $view.hide();
                $edit.hide();
                $delete.hide();
            }
        },

        /* ================= DELETE ================= */
        deleteData: function () {
            const self = this;
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
                success: function () {
                    self.select
                        .find("option[value='" + selectedId + "']")
                        .remove();

                    self.select.val(null).trigger("change");
                    alert("Data deleted successfully");
                }
            });
        },

        /* ================= POPUP ================= */
        openPopup: function (type) {
            const isEdit = type === "edit";
            const isView = type === "view";
            const frameId = "formPopup_" + this.config.paramName;

            let popupTitle = "Add Data";
            if (isEdit) popupTitle = "Edit Data";
            else if (isView) popupTitle = "View Data";

            if (window.JPopup && !isEdit && !isView) {
                JPopup.create(
                    frameId,
                    popupTitle,
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
                "/form/embed";

            if (isView) {
                url += "?_mode=view&_submitButtonLabel=";
            } else {
                url += "?_submitButtonLabel=" + (isEdit ? "Save" : "Submit");
            }

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
                _callback: isView
                    ? ""
                    : (this.config.paramName + (isEdit ? "_editDataCallback" : "_addDataCallback")),
                _nonce: this.config.crudFormNonce,
                _setting: isView ? JSON.stringify({ readonly: "true" }) : "{}",
                defaultValues: "{}"
            };

            if (isEdit || isView) {
                const $select = this.select;
                let $selectedOption = $select.find("option:selected");
                let encryptedId = this.getValue();
                let plainId = $selectedOption.attr("data-id");

                if (!plainId) plainId = encryptedId;
                if (!plainId || plainId === "__add_data__") return;

                params.id = plainId;
            }

            if (window.JPopup) {
                JPopup.show(frameId, url, params, popupTitle, "80%", "80%");
            }
        },

        /* ================= REGISTER CALLBACK ================= */
        registerCrudCallbacks: function () {
            const self = this;

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
        }
    };

    window.AutofillSelectBoxCrudController = {
        instances: {},
        init: function ($select, config) {
            if (!$select || !$select.length) return;
            const instance = new AutofillSelectBoxCrudInstance($select, config);
            if (config && config.paramName) {
                this.instances[config.paramName] = instance;
            }
            return instance;
        }
    };

})();
