package com.kinnarastudio.kecakplugins.autofillselectbox;

import com.kinnarastudio.commons.Try;
import com.kinnarastudio.commons.jsonstream.JSONStream;
import org.joget.apps.app.model.AppDefinition;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.form.lib.CheckBox;
import org.joget.apps.form.lib.Radio;
import org.joget.apps.form.lib.SelectBox;
import org.joget.apps.form.lib.SubForm;
import org.joget.apps.form.model.*;
import org.joget.apps.form.service.FormService;
import org.joget.apps.form.service.FormUtil;
import org.joget.commons.util.LogUtil;
import org.joget.plugin.base.PluginManager;
import org.joget.plugin.base.PluginWebSupport;
import org.json.JSONException;
import org.json.JSONObject;
import org.kecak.apps.exception.ApiException;
import org.springframework.context.ApplicationContext;

import javax.annotation.Nonnull;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.util.*;
import java.util.function.Predicate;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * @author aristo
 * <p>
 * Autofill other elements based on this element's value as ID
 */
public class AutofillSelectBox extends SelectBox implements PluginWebSupport {
    private final static String PARAMETER_ID = "id";
    private final static String PARAMETER_APP_ID = "appId";
    private final static String PARAMETER_APP_VERSION = "appVersion";

    private final static String BODY_FORM_ID = "FORM_ID";
    private final static String BODY_SECTION_ID = "SECTION_ID";
    private final static String BODY_FIELD_ID = "FIELD_ID";

    private final static String PROPERTY_AUTOFILL_LOAD_BINDER = "autofillLoadBinder";

    private final static long PAGE_SIZE = 10;

    @Override
    public void webService(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            if ("GET".equals(request.getMethod())) {
                super.webService(request, response);
            } else if ("POST".equals(request.getMethod())) {
                final ApplicationContext appContext = AppUtil.getApplicationContext();
                final AppDefinition appDefinition = AppUtil.getCurrentAppDefinition();

                try {
                    final JSONObject body = constructRequestBody(request);
                    final String formDefId = getRequiredBodyPayload(body, BODY_FORM_ID);
                    final String sectionId = getRequiredBodyPayload(body, BODY_SECTION_ID);
                    final String fieldId = getRequiredBodyPayload(body, BODY_FIELD_ID);
                    final String id = getRequiredBodyPayload(body, PARAMETER_ID);

                    final JSONObject requestParameter = new JSONObject(getRequiredBodyPayload(body, "requestParameter"));

                    // build form
                    @Nonnull final Form form = Optional.ofNullable(appDefinition)
                            .map(a -> generateForm(a, formDefId))
                            .orElseThrow(() -> new ApiException(HttpServletResponse.SC_BAD_REQUEST, "Error generating form [" + formDefId + "]"));

                    final FormData formData = new FormData();
                    final Element section = FormUtil.findElement(sectionId, form, formData, true);
                    final Element elementSelectBox = FormUtil.findElement(fieldId, section, formData, true);
                    if (!(elementSelectBox instanceof AutofillSelectBox)) {
                        throw new ApiException(HttpServletResponse.SC_BAD_REQUEST, "Element ID [" + fieldId + "] is not found in form [" + formDefId + "]");
                    }

                    final Map<String, Object> autofillLoadBinder = (Map<String, Object>) elementSelectBox.getProperty(PROPERTY_AUTOFILL_LOAD_BINDER);

                    final PluginManager pluginManager = (PluginManager) appContext.getBean("pluginManager");
                    final FormBinder loadBinder = (FormBinder) pluginManager.getPlugin(String.valueOf(autofillLoadBinder.get(FormUtil.PROPERTY_CLASS_NAME)));
                    final String primaryKey = ((AutofillSelectBox) elementSelectBox).decrypt(id);

                    if (loadBinder != null) {
                        try {
                            final Map<String, Object> properties = (Map<String, Object>) autofillLoadBinder.get(FormUtil.PROPERTY_PROPERTIES);
                            loadBinder.setProperties(properties);
                            form.setLoadBinder((FormLoadBinder) loadBinder);
                        } catch (Exception e) {
                            LogUtil.error(getClassName(), e, "Error configuring load binder");
                        }

                        requestParameter.put(PARAMETER_APP_ID, appDefinition.getAppId());
                        requestParameter.put(PARAMETER_APP_VERSION, appDefinition.getVersion());

                        final JSONObject data = loadFormData(form, primaryKey, requestParameter);

                        response.setStatus(HttpServletResponse.SC_OK);
                        response.getWriter().write(data.toString());
                    } else {
                        throw new ApiException(HttpServletResponse.SC_NOT_FOUND, "Load binder not found");
                    }

                } catch (JSONException e) {
                    throw new ApiException(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e);
                }
            } else {
                throw new ApiException(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Method [" + request.getMethod() + "] is not supported");
            }
        } catch (ApiException e) {
            response.sendError(e.getErrorCode(), e.getMessage());
            LogUtil.error(getClassName(), e, e.getMessage());
        }
    }

    @Override
    public String getLabel() {
        return "Autofill Select Box";
    }

    @Override
    public String getClassName() {
        return getClass().getName();
    }

    @Override
    public String getPropertyOptions() {
        return AppUtil.readPluginResource(getClass().getName(), "/properties/AutofillSelectBox.json", new String[]{PROPERTY_AUTOFILL_LOAD_BINDER}, true, "message/form/SelectBox").replaceAll("\"", "'");
    }

    @Override
    public String getName() {
        return getLabel();
    }

    @Override
    public String getVersion() {
        PluginManager pluginManager = (PluginManager) AppUtil.getApplicationContext().getBean("pluginManager");
        ResourceBundle resourceBundle = pluginManager.getPluginMessageBundle(getClassName(), "/messages/BuildNumber");
        String buildNumber = resourceBundle.getString("buildNumber");
        return buildNumber;
    }

    @Override
    public String getDescription() {
        return getClass().getPackage().getImplementationTitle();
    }

    @Override
    public String getFormBuilderCategory() {
        return "Kecak";
    }

    @Override
    public String renderTemplate(FormData formData, Map dataModel) {
        String template = "AutofillSelectBox.ftl";
        return renderTemplate(formData, dataModel, template);
    }

    @Override
    protected void dynamicOptions(FormData formData) {
        FormUtil.setAjaxOptionsElementProperties(this, formData);
    }

    protected String renderTemplate(FormData formData, Map dataModel, String template) {
        dataModel.replace("element", this);
        Form rootForm = FormUtil.findRootForm(this);

        dynamicOptions(formData);

//        FormUtil.setAjaxOptionsElementProperties(this, formData);

        // set value
        @Nonnull final List<String> databasePlainValues = Arrays.stream(FormUtil.getElementPropertyValues(this, formData))
                .collect(Collectors.toList());

        @Nonnull final List<String> databaseEncryptedValues = new ArrayList<>();

        @Nonnull final List<Map> optionsMap = getOptionMap(formData)
                .stream()
                .peek(r -> {
                    final String value = r.get(FormUtil.PROPERTY_VALUE).toString();
                    final String encrypted = encrypt(value);

                    r.put(FormUtil.PROPERTY_VALUE, encrypted);

                    if (databasePlainValues.stream().anyMatch(value::equals)) {
                        databaseEncryptedValues.add(encrypted);
                    }
                })
                .collect(Collectors.toList());

        dataModel.put("values", databaseEncryptedValues);
        dataModel.put("options", optionsMap);


        dataModel.put("className", getClassName());
        dataModel.put("width", getPropertyString("size") == null || getPropertyString("size").isEmpty() ? "resolve" : (getPropertyString("size").replaceAll("[^0-9]+]", "") + "%"));
        dataModel.put("keyField", PARAMETER_ID);

        final AppDefinition appDefinition = AppUtil.getCurrentAppDefinition();
        final String appId = appDefinition.getAppId();
        final long appVersion = appDefinition.getVersion();
        final String formDefId = Optional.ofNullable(rootForm).map(f -> f.getPropertyString(FormUtil.PROPERTY_ID)).orElse("");
        final String fieldId = getPropertyString(FormUtil.PROPERTY_ID);

        final String nonce = generateNonce(appId, String.valueOf(appVersion), formDefId, fieldId);
        dataModel.put("nonce", nonce);

        @Deprecated
        Map<String, String> fieldTypes = new HashMap<>();
        getFieldTypes(rootForm, fieldTypes);
        dataModel.put("fieldTypes", fieldTypes);

        try {
            final JSONObject requestBody = new JSONObject();
            if (rootForm != null) {
                requestBody.put(BODY_FORM_ID, rootForm.getPropertyString(FormUtil.PROPERTY_ID));
            }

            Map<String, Object> autofillLoadBinder = (Map<String, Object>) getProperty(PROPERTY_AUTOFILL_LOAD_BINDER);
            if (autofillLoadBinder != null) {
                requestBody.put(BODY_FIELD_ID, getPropertyString(FormUtil.PROPERTY_ID));
            }

            Section section = Utilities.getElementSection(this);
            if (section != null) {
                requestBody.put(BODY_SECTION_ID, section.getPropertyString(FormUtil.PROPERTY_ID));
            }

            dataModel.put("requestBody", requestBody);
        } catch (Exception e) {
            LogUtil.error(getClassName(), e, "Error generating form json");
        }

        final Map<String, String> fieldsMapping = generateFieldsMapping(rootForm, "true".equals(getPropertyString("lazyMapping")), (Object[]) getProperty("autofillFields"));
        dataModel.put("fieldsMapping", fieldsMapping);
        dataModel.put("fieldsMappingJson", new JSONObject(fieldsMapping));

        dataModel.put(PARAMETER_APP_ID, appDefinition.getAppId());
        dataModel.put(PARAMETER_APP_VERSION, appDefinition.getVersion());

        dataModel.put("fieldType", "Autofill".toUpperCase());

        final Form form = FormUtil.findRootForm(this);
        if (form != null)
            dataModel.put("formDefId", form.getPropertyString(FormUtil.PROPERTY_ID));

        dataModel.put("pageSize", PAGE_SIZE);

        String html = FormUtil.generateElementHtml(this, formData, template, dataModel);
        return html;
    }

    protected Map<String, String> generateFieldsMapping(Form rootForm, boolean lazyMapping, Object[] autofillFields) {
        Map<String, String> fieldsMapping = new HashMap<>();
        if (lazyMapping) {
            final String selectBoxId = getPropertyString(FormUtil.PROPERTY_ID);
            iterateLazyFieldsMapping(fieldsMapping, rootForm, element -> {
                String id = element.getPropertyString(FormUtil.PROPERTY_ID);
                return !(element instanceof SubForm || element instanceof Column || element instanceof Section || element instanceof FormButton)
                        && id != null && !id.isEmpty() && !id.equals(selectBoxId);
            });
        }

        if (autofillFields != null) {
            for (Object o : autofillFields) {
                Map<String, String> column = (Map<String, String>) o;
                String formField = column.get("formField");
                String resultField = column.get("resultField");
                if (!resultField.isEmpty())
                    fieldsMapping.put(formField, resultField);
                else
                    fieldsMapping.remove(formField);
            }
        }

        return fieldsMapping;
    }

    @Override
    public String getFormBuilderTemplate() {
        return "<label class='label'>" + getLabel() + "</label><select><option>Option</option></select>";
    }

    /**
     * Recursively iterating elements' children
     *
     * @param fieldsMapping
     * @param element
     * @param condition
     */
    private void iterateLazyFieldsMapping(final Map<String, String> fieldsMapping, final Element element, Predicate<Element> condition) {
        if (element != null) {
            for (Element child : element.getChildren()) {
                if (condition.test(child)) {
                    String id = child.getPropertyString(FormUtil.PROPERTY_ID);
                    fieldsMapping.put(id, id);
                }

                iterateLazyFieldsMapping(fieldsMapping, child, condition);
            }
        }
    }

    @Deprecated
    protected void getFieldTypes(Element element, Map<String, String> types) {
        if (element != null) {
            String id = element.getPropertyString(FormUtil.PROPERTY_ID);

            if (id != null && !id.isEmpty()) {
                if ("true".equalsIgnoreCase(element.getPropertyString(FormUtil.PROPERTY_READONLY)) && "true".equalsIgnoreCase(element.getPropertyString(FormUtil.PROPERTY_READONLY_LABEL)))
                    types.put(id, "LABEL");
                else if (element instanceof CheckBox)
                    types.put(id, "CHECK_BOXES");
                else if (element instanceof Radio)
                    types.put(id, "RADIOS");
                else if (element.getClassName().matches(".+Grid$"))
                    types.put(id, "GRIDS");
                else if (element instanceof SelectBox)
                    types.put(id, "SELECT_BOXES");
                else
                    types.put(id, "OTHERS");
            }

            for (Element child : element.getChildren()) {
                getFieldTypes(child, types);
            }
        }
    }


    protected JSONObject constructRequestBody(HttpServletRequest request) throws IOException, JSONException {
        try (BufferedReader bf = request.getReader()) {
            return new JSONObject(bf.lines().collect(Collectors.joining()));
        }
    }

    /**
     * Load Form Data
     *
     * @param form
     * @param primaryKey
     * @param jsonRequestParameter
     * @return
     */
    protected JSONObject loadFormData(Form form, String primaryKey, JSONObject jsonRequestParameter) {
        ApplicationContext appContext = AppUtil.getApplicationContext();
        FormService formService = (FormService) appContext.getBean("formService");
        final FormData formData = new FormData();
        formData.setPrimaryKeyValue(primaryKey);

        JSONStream.of(jsonRequestParameter, Try.onBiFunction(JSONObject::getString))
                .forEach(e -> formData.addRequestParameterValues(e.getKey(), new String[]{e.getValue()}));

        formService.executeFormLoadBinders(form, formData);

        return Optional.ofNullable(formData.getLoadBinderData(form))
                .map(Collection::stream)
                .orElseGet(Stream::empty)
                .findFirst()
                .map(JSONObject::new)
                .orElseGet(JSONObject::new);
    }

    protected String getRequiredBodyPayload(JSONObject payload, String key) throws ApiException {
        return Optional.ofNullable(payload)
                .map(j -> j.optString(key))
                .orElseThrow(() -> new ApiException(HttpServletResponse.SC_BAD_REQUEST, "Body payload [" + key + "] is not found"));
    }

    protected String getOptionalBodyPayload(JSONObject payload, String key, String defaultValue) {
        return Optional.ofNullable(payload)
                .map(j -> j.optString(key))
                .filter(s -> !s.isEmpty())
                .orElse(defaultValue);
    }

    @Override
    public int getFormBuilderPosition() {
        return 100;
    }
}
