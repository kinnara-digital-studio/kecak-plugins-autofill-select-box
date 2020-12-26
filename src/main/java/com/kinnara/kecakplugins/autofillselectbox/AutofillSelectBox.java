package com.kinnara.kecakplugins.autofillselectbox;

import com.kinnara.kecakplugins.autofillselectbox.commons.AutofillException;
import com.kinnara.kecakplugins.autofillselectbox.commons.RestApiException;
import org.joget.apps.app.dao.AppDefinitionDao;
import org.joget.apps.app.dao.FormDefinitionDao;
import org.joget.apps.app.model.AppDefinition;
import org.joget.apps.app.model.FormDefinition;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.form.lib.CheckBox;
import org.joget.apps.form.lib.Radio;
import org.joget.apps.form.lib.SelectBox;
import org.joget.apps.form.lib.SubForm;
import org.joget.apps.form.model.*;
import org.joget.apps.form.service.FormService;
import org.joget.apps.form.service.FormUtil;
import org.joget.commons.util.LogUtil;
import org.joget.commons.util.SecurityUtil;
import org.joget.plugin.base.PluginManager;
import org.joget.plugin.base.PluginWebSupport;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.springframework.context.ApplicationContext;

import javax.annotation.Nonnull;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.util.*;
import java.util.function.Predicate;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * 
 * @author aristo
 *
 * Autofill other elements based on this element's value as ID
 * 
 */
public class AutofillSelectBox extends  SelectBox implements PluginWebSupport, AceFormElement, AdminLteFormElement{
	private final WeakHashMap<String, Form> formCache = new WeakHashMap<>();

	private Element controlElement;

	private final static String PARAMETER_ID = "id";
	private final static String PARAMETER_APP_ID = "appId";
	private final static String PARAMETER_APP_VERSION = "appVersion";

	private final static String BODY_FORM_ID = "FORM_ID";
	private final static String BODY_SECTION_ID = "SECTION_ID";
	private final static String BODY_FIELD_ID = "FIELD_ID";

	private final static String PROPERTY_AUTOFILL_LOAD_BINDER = "autofillLoadBinder";

	private final static long PAGE_SIZE = 10;

	public void webService(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		final ApplicationContext appContext = AppUtil.getApplicationContext();
		final AppDefinitionDao appDefinitionDao = (AppDefinitionDao) appContext.getBean("appDefinitionDao");

		try {
			if ("GET".equals(request.getMethod())) {
				// Get Options Binder Data
				final String appId = request.getParameter("appId");
				final String appVersion = request.getParameter("appVersion");
				final AppDefinition appDefinition = appDefinitionDao.loadVersion(appId, Long.parseLong(appVersion));

				// method for paging
				final String formDefId = getRequiredParameter(request, "formDefId");
				final String[] fieldIds = request.getParameterValues("fieldId");
				final String search = request.getParameter("search");
				final Pattern searchPattern = Pattern.compile(search == null ? "" : search, Pattern.CASE_INSENSITIVE);
				final long page = request.getParameter("page") == null ? PAGE_SIZE : Long.parseLong(request.getParameter("page"));
				final String grouping = request.getParameter("grouping");

				final FormData formData = new FormData();
				final Form form = generateForm(appDefinition, formDefId);

				final JSONArray jsonResults = new JSONArray();
				for (String fieldId : fieldIds) {
					Element element = FormUtil.findElement(fieldId, form, formData);
					if (element == null)
						continue;

					final boolean encryption = "true".equalsIgnoreCase(element.getPropertyString("encryption"));

					FormRowSet optionsRowSet;
					if (element.getOptionsBinder() == null) {
						optionsRowSet = (FormRowSet) element.getProperty(FormUtil.PROPERTY_OPTIONS);
					} else {
						FormUtil.executeOptionBinders(element, formData);
						optionsRowSet = formData.getOptionsBinderData(element, null);
					}

					int skip = (int) ((page - 1) * PAGE_SIZE);
					int pageSize = (int) PAGE_SIZE;
					for (int i = 0, size = optionsRowSet.size(); i < size && pageSize > 0; i++) {
						FormRow formRow = optionsRowSet.get(i);
						if (searchPattern.matcher(formRow.getProperty(FormUtil.PROPERTY_LABEL)).find() && (
								grouping == null
										|| grouping.isEmpty()
										|| grouping.equalsIgnoreCase(formRow.getProperty(FormUtil.PROPERTY_GROUPING)))) {

							if (skip > 0) {
								skip--;
							} else {
								try {
									JSONObject jsonResult = new JSONObject();
									jsonResult.put("id", encrypt(formRow.getProperty(FormUtil.PROPERTY_VALUE), encryption));
									jsonResult.put("text", formRow.getProperty(FormUtil.PROPERTY_LABEL));
									jsonResults.put(jsonResult);
									pageSize--;
								} catch (JSONException ignored) {
								}
							}
						}
					}
				}

				// I wonder why these codes don't work; they got some NULL POINTER EXCEPTION
				//        JSONArray jsonResults = new JSONArray((optionsRowSet).stream()
				//                .filter(Objects::nonNull)
				//                .filter(formRow -> searchPattern.matcher(formRow.getProperty(FormUtil.PROPERTY_LABEL)).find())
				//                .filter(formRow -> grouping == null
				//                        || formRow.getProperty(FormUtil.PROPERTY_GROUPING) == null
				//                        || grouping.isEmpty()
				//                        || formRow.getProperty(FormUtil.PROPERTY_GROUPING).isEmpty()
				//                        || grouping.equalsIgnoreCase(formRow.getProperty(FormUtil.PROPERTY_GROUPING)))
				//                .skip((page - 1) * PAGE_SIZE)
				//                .limit(PAGE_SIZE)
				//                .map(formRow -> {
				//                    final Map<String, String> map = new HashMap<>();
				//                    map.put("id", formRow.getProperty(FormUtil.PROPERTY_VALUE));
				//                    map.put("text", formRow.getProperty(FormUtil.PROPERTY_LABEL));
				//                    return map;
				//                })
				//                .collect(Collectors.toList()));

				try {
					JSONObject jsonPagination = new JSONObject();
					jsonPagination.put("more", jsonResults.length() >= PAGE_SIZE);

					JSONObject jsonData = new JSONObject();
					jsonData.put("results", jsonResults);
					jsonData.put("pagination", jsonPagination);

					response.setContentType("application/json");
					response.getWriter().write(jsonData.toString());
				} catch (JSONException e) {
					throw new RestApiException(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e);
				}
			} else if ("POST".equals(request.getMethod())) {

				try {
					JSONObject body = constructRequestBody(request);

					final String appId = body.getString(PARAMETER_APP_ID);
					final String appVersion = body.getString(PARAMETER_APP_VERSION);
					final AppDefinition appDefinition = AppUtil.getCurrentAppDefinition();
					final String formDefId = getRequiredBodyPayload(body, BODY_FORM_ID);
					final String sectionId = getRequiredBodyPayload(body, BODY_SECTION_ID);
					final String fieldId = getRequiredBodyPayload(body, BODY_FIELD_ID);

					JSONObject requestParameter = body.getJSONObject("requestParameter");

					// build form
					@Nonnull
					Form form = Optional.ofNullable(appDefinition)
							.map(a -> generateForm(a, formDefId))
							.orElseThrow(() -> new RestApiException(HttpServletResponse.SC_BAD_REQUEST, "Error generating form [" + formDefId + "]"));

					FormData formData = new FormData();
					Element section = FormUtil.findElement(sectionId, form, formData, true);
					Element elementSelectBox = FormUtil.findElement(fieldId, section, formData, true);
					Map<String, Object> autofillLoadBinder = (Map<String, Object>) elementSelectBox.getProperty(PROPERTY_AUTOFILL_LOAD_BINDER);

					PluginManager pluginManager = (PluginManager) appContext.getBean("pluginManager");
					FormBinder loadBinder = (FormBinder) pluginManager.getPlugin(String.valueOf(autofillLoadBinder.get(FormUtil.PROPERTY_CLASS_NAME)));

					boolean encryption = "true".equalsIgnoreCase(elementSelectBox.getPropertyString("encryption"));
					String primaryKey = decrypt(body.getString(PARAMETER_ID), encryption);

					if (loadBinder != null) {
						try {
							Map<String, Object> properties = (Map<String, Object>) autofillLoadBinder.get(FormUtil.PROPERTY_PROPERTIES);
							loadBinder.setProperties(properties);
							form.setLoadBinder((FormLoadBinder) loadBinder);
						} catch (Exception e) {
							LogUtil.error(getClassName(), e, "Error configuring load binder");
						}

						requestParameter.put(PARAMETER_APP_ID, appId);
						requestParameter.put(PARAMETER_APP_VERSION, appVersion);

						JSONObject data = loadFormData(form, primaryKey, requestParameter);

						response.setStatus(HttpServletResponse.SC_OK);
						response.getWriter().write(data.toString());
					} else {
						throw new RestApiException(HttpServletResponse.SC_NOT_FOUND, "Load binder not found");
					}

				} catch (JSONException e) {
					throw new RestApiException(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e);
				}
			} else {
				throw new RestApiException(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Method [" + request.getMethod() + "] is not supported");
			}
		} catch (RestApiException e) {
			response.sendError(e.getErrorCode(), e.getMessage());
			LogUtil.error(getClassName(), e, e.getMessage());
		}
	}
	
	@Override
	public String getLabel() {
		return "Autofill SelectBox";
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
		return getLabel() + getVersion();
	}

	@Override
	public String getVersion() {
		return getClass().getPackage().getImplementationVersion();
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
	public FormData formatDataForValidation(FormData formData) {
		String[] paramValues = FormUtil.getRequestParameterValues(this, formData);

		if ((paramValues == null || paramValues.length == 0) && FormUtil.isFormSubmitted(this, formData)) {
			String paramName = FormUtil.getElementParameterName(this);
			formData.addRequestParameterValues(paramName, new String[]{""});
		} else {
			formData.getRequestParams()
					.entrySet()
					.forEach(e -> e.setValue(Arrays.stream(e.getValue()).map(this::decrypt).toArray(String[]::new)));
		}

		return formData;
	}

	@Override
	public FormRowSet formatData(FormData formData) {
		FormRowSet rowSet = null;

		// get value
		String id = getPropertyString(FormUtil.PROPERTY_ID);
		if (id != null) {
			String[] values = Arrays.stream(FormUtil.getElementPropertyValues(this, formData))
					// descrypt before storing to database
					.map(this::decrypt)
					.toArray(String[]::new);
			if (values.length > 0) {
				// check for empty submission via parameter
				String[] paramValues = FormUtil.getRequestParameterValues(this, formData);
				if ((paramValues == null || paramValues.length == 0) && FormUtil.isFormSubmitted(this, formData)) {
					values = new String[]{encrypt("")};
				}

				// formulate values
				String delimitedValue = FormUtil.generateElementPropertyValues(values);

				// set value into Properties and FormRowSet object
				FormRow result = new FormRow();
				result.setProperty(id, delimitedValue);
				rowSet = new FormRowSet();
				rowSet.add(result);
			}

			// remove duplicate based on label (because list is sorted by label by default)
			if("true".equals(getProperty("removeDuplicates")) && rowSet != null) {
				FormRowSet newResults = new FormRowSet();
				String currentValue = null;
				for(FormRow row : rowSet) {
					String label = row.getProperty(FormUtil.PROPERTY_LABEL);
					if(currentValue == null || !currentValue.equals(label)) {
						currentValue = label;
						newResults.add(row);
					}
				}

				rowSet = newResults;
			}
		}

		return rowSet;
	}
	@Override
	public String renderTemplate(FormData formData, Map dataModel) {
		String template = "AutofillSelectBox.ftl";
		return renderTemplate(formData,dataModel,template);
	}

	public String renderTemplate(FormData formData, Map dataModel, String template) {
		dataModel.replace("element", this);
        Form rootForm = FormUtil.findRootForm(this);

        dynamicOptions(formData);

        // set value
		@Nonnull
		final List<String> databasePlainValues = Arrays.stream(FormUtil.getElementPropertyValues(this, formData))
				.collect(Collectors.toList());

		@Nonnull
		final List<String> databaseEncryptedValues = new ArrayList<>();

		@Nonnull
		final List<FormRow> optionsMap = getOptionMap(formData)
				.stream()
				.peek(r -> {
					final String value = r.getProperty(FormUtil.PROPERTY_VALUE);
					final String encrypted = encrypt(value);

					r.put(FormUtil.PROPERTY_VALUE, encrypted);

					if(databasePlainValues.stream().anyMatch(s -> s.equals(value))) {
						databaseEncryptedValues.add(encrypted);
					}
				})
				.collect(Collectors.toList());

		dataModel.put("values", databaseEncryptedValues);
		dataModel.put("options", optionsMap);

		Collection<Map<String, String>> valuesMap = databaseEncryptedValues.stream()
				.filter(s -> !s.isEmpty())
				.map(s -> {
					Map<String, String> map = new HashMap<>();
					map.put("value", s);

					final FormRow lookingFor = new FormRow();
					lookingFor.put("value", s);

					int index = Collections.binarySearch(optionsMap, lookingFor, Comparator.comparing(m -> m.getProperty("value")));
					map.put("label", index >= 0 ? optionsMap.get(index).getProperty(FormUtil.PROPERTY_LABEL) : s);
					return map;
				})
				.collect(Collectors.toList());
		dataModel.put("optionsValues", valuesMap);

        dataModel.put("className", getClassName());
		dataModel.put("width", getPropertyString("size") == null || getPropertyString("size").isEmpty() ? "resolve" : (getPropertyString("size").replaceAll("[^0-9]+]", "") + "%"));
        dataModel.put("keyField", PARAMETER_ID);
        
        Map<String, String> fieldTypes = new HashMap<>();
        getFieldTypes(rootForm, fieldTypes);
        dataModel.put("fieldTypes", fieldTypes);

		try {
			JSONObject requestBody = new JSONObject();
			if (rootForm != null) {
				requestBody.put(BODY_FORM_ID, rootForm.getPropertyString(FormUtil.PROPERTY_ID));
			}

			Map<String, Object> autofillLoadBinder = (Map<String, Object>) getProperty(PROPERTY_AUTOFILL_LOAD_BINDER);
			if (autofillLoadBinder != null) {
				requestBody.put(BODY_FIELD_ID, getPropertyString(FormUtil.PROPERTY_ID));
			}

			Section section = Utilities.getElementSection(this);
			if(section != null) {
				requestBody.put(BODY_SECTION_ID, section.getPropertyString(FormUtil.PROPERTY_ID));
			}

			dataModel.put("requestBody", requestBody);
		} catch (Exception e) {
			LogUtil.error(getClassName(), e, "Error generating form json");
		}
        
        Map<String, String> fieldsMapping = generateFieldsMapping(rootForm, "true".equals(getPropertyString("lazyMapping")), (Object[])getProperty("autofillFields"));
        dataModel.put("fieldsMapping", fieldsMapping);

        AppDefinition appDefinition = AppUtil.getCurrentAppDefinition();
        dataModel.put(PARAMETER_APP_ID, appDefinition.getAppId());
        dataModel.put(PARAMETER_APP_VERSION, appDefinition.getVersion());

        dataModel.put("fieldType", getLabel().toUpperCase());

		final Form form = FormUtil.findRootForm(this);
		if(form != null)
			dataModel.put("formDefId", form.getPropertyString(FormUtil.PROPERTY_ID));

		dataModel.put("pageSize", PAGE_SIZE);

        String html = FormUtil.generateElementHtml(this, formData, template, dataModel);
        return html;
	}
	
	private Map<String, String> generateFieldsMapping(Form rootForm, boolean lazyMapping, Object[] autofillFields) {
		Map<String, String> fieldsMapping = new HashMap<>();
		if(lazyMapping) {
			final String selectBoxId = getPropertyString(FormUtil.PROPERTY_ID);
			iterateLazyFieldsMapping(fieldsMapping, rootForm, element -> {
				String id = element.getPropertyString(FormUtil.PROPERTY_ID);
				return !(element instanceof SubForm || element instanceof Column || element instanceof Section || element instanceof FormButton)
						&& id != null && !id.isEmpty() && !id.equals(selectBoxId);
			});
		}

		if(autofillFields != null) {
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

	protected void dynamicOptions(FormData formData) {
		if (getControlElement(formData) != null) {
			setProperty("controlFieldParamName", FormUtil.getElementParameterName(getControlElement(formData)));

			FormUtil.setAjaxOptionsElementProperties(this, formData);
		}
	}

	@Override
	public Element getControlElement(FormData formData) {
		if (controlElement == null) {
			if (getPropertyString("controlField") != null && !getPropertyString("controlField").isEmpty()) {
				Form form = FormUtil.findRootForm(this);
				controlElement = FormUtil.findElement(getPropertyString("controlField"), form, formData);
			}
		}
		return controlElement;
	}

	@Override
	public String getFormBuilderTemplate() {
		return "<label class='label'>" + getName() + "</label><select><option>Option</option></select>";
	}

	/**
	 * Recursively iterating elements' children
	 * @param fieldsMapping
	 * @param element
	 * @param condition
	 */
	private void iterateLazyFieldsMapping(Map<String, String> fieldsMapping, Element element, Predicate<Element> condition) {
		if(element != null) {
			for(Element child : element.getChildren()) {
				if(condition.test(child)) {
					String id = child.getPropertyString(FormUtil.PROPERTY_ID);
					fieldsMapping.put(id, id);
				}
			
				iterateLazyFieldsMapping(fieldsMapping, child, condition);
			}
		}
	}
	
	private void getFieldTypes(Element element, Map<String, String> types) {
		if(element != null) {
			String id = element.getPropertyString(FormUtil.PROPERTY_ID);
			
			if(id != null && !id.isEmpty()) {
				if("true".equalsIgnoreCase(element.getPropertyString(FormUtil.PROPERTY_READONLY)) && "true".equalsIgnoreCase(element.getPropertyString(FormUtil.PROPERTY_READONLY_LABEL)))
					types.put(id, "LABEL");
				else if(element instanceof CheckBox)
					types.put(id, "CHECK_BOXES");
				else if(element instanceof Radio)
					types.put(id, "RADIOS");
				else if(element.getClassName().matches(".+Grid$"))
					types.put(id, "GRIDS");
				else if(element instanceof SelectBox)
					types.put(id, "SELECT_BOXES");
				else
					types.put(id, "OTHERS");

//				LogUtil.info(getClassName(), "form ["+FormUtil.findRootForm(element).getPropertyString("id")+"] element ["+id+"] type ["+types.get(id)+"]");
			}
			
			for(Element child : element.getChildren()) {
				getFieldTypes(child, types);
			}
		}
	}
	
	private JSONObject getFormJson(String formDefId) throws JSONException {
		AppDefinition appDef = AppUtil.getCurrentAppDefinition();
		ApplicationContext appContext = AppUtil.getApplicationContext();
		if(appDef != null) {
			FormDefinitionDao formDefinitionDao = (FormDefinitionDao)appContext.getBean("formDefinitionDao");
			FormDefinition formDef = formDefinitionDao.loadById(formDefId, appDef);
			return new JSONObject(formDef.getJson());
		}
		
		return null;
	}
	
	private JSONObject constructRequestBody(HttpServletRequest request) throws IOException, JSONException {
		try(BufferedReader bf = request.getReader()) {
			return new JSONObject(bf.lines().collect(Collectors.joining()));
		}
	}
	
	private Map<String, Object> jsonToMap(JSONObject json) {
		Map<String, Object> result = new HashMap<String, Object>();
		Iterator<String> i = json.keys();
		while(i.hasNext()) {
			String key = i.next();
			try {
				String value = json.getString(key);
				result.put(key, value);
			} catch (JSONException e) {
				e.printStackTrace();
			}
		}
		return result;
	}
	
	private JSONArray formRowSetToJson(FormRowSet data) {
		JSONArray result = new JSONArray();
		if(data != null) {		
			for(FormRow row : data) {
				result.put(row);
			}
		}
		return result;
	}

	/**
	 * Load Form Data
	 *
	 * @param form
	 * @param primaryKey
	 * @param jsonRequestParameter
	 * @return
	 */
	private JSONObject loadFormData(Form form, String primaryKey, JSONObject jsonRequestParameter) {
		ApplicationContext appContext = AppUtil.getApplicationContext();
		FormService formService = (FormService) appContext.getBean("formService");
		FormData formData = new FormData();
		formData.setPrimaryKeyValue(primaryKey);

		Iterator<String> i = jsonRequestParameter.keys();
		while (i.hasNext()) {
			String key = i.next();
			try {
				formData.addRequestParameterValues(key, new String[] { jsonRequestParameter.getString(key) });
			} catch (JSONException ignored) { }
		}

		formData = formService.executeFormLoadBinders(form, formData);
		return Optional.ofNullable(formData.getLoadBinderData(form))
				.map(Collection::stream)
				.orElseGet(Stream::empty)
				.findFirst()
				.map(JSONObject::new)
				.orElseGet(JSONObject::new);
	}

	protected String encrypt(String rawContent) {
		return encrypt(rawContent, "true".equalsIgnoreCase(getPropertyString("encryption")));
	}

	protected String encrypt(String rawContent, boolean encryption) {
		if(encryption) {
			String encrypted = SecurityUtil.encrypt(rawContent);
			if(verifyEncryption(rawContent, encrypted)) {
				return encrypted;
			} else {
				LogUtil.warn(getClassName(), "Failed to verify encrypted value, use raw content");
				return rawContent;
			}
		}
		return rawContent;
	}

	/**
	 * For testing purpose
	 * @param rawContent
	 * @param encryptedValue
	 * @return
	 */
	private boolean verifyEncryption(String rawContent, String encryptedValue) {
		// try to decrypt
		return (rawContent.equals(decrypt(encryptedValue)));
	}

	protected String decrypt(String protectedContent) {
		return decrypt(protectedContent, "true".equalsIgnoreCase(getPropertyString("encryption")));
	}

	protected String decrypt(String protectedContent, boolean encryption) {
		if(encryption) {
			return SecurityUtil.decrypt(protectedContent);
		}
		return protectedContent;
	}

	@Override
	public String renderAceTemplate(FormData formData, Map map) {
		String template = "AutofillSelectBoxAce.ftl";
		return renderTemplate(formData,map,template);
	}

	@Override
	public String renderAdminLteTemplate(FormData formData, Map map) {
		String template = "AutofillSelectBoxAdminLte.ftl";
		return renderTemplate(formData,map,template);
	}

	protected String getRequiredBodyPayload(JSONObject payload, String key) throws RestApiException {
		return Optional.ofNullable(payload)
				.map(j -> j.optString(key))
				.orElseThrow(() -> new RestApiException(HttpServletResponse.SC_BAD_REQUEST, "Body payload [" + key + "] is not found"));
	}

	protected String getOptionalBodyPayload(JSONObject payload, String key, String defaultValue) {
		return Optional.ofNullable(payload)
				.map(j -> j.optString(key))
				.filter(s -> !s.isEmpty())
				.orElse(defaultValue);
	}

	protected String getRequiredParameter(HttpServletRequest request, String key) throws RestApiException {
		return Optional.of(key)
				.map(request::getParameter)
				.filter(s -> !s.isEmpty())
				.orElseThrow(() -> new RestApiException(HttpServletResponse.SC_BAD_REQUEST, "Missing request parameter ["+key+"]"));
	}
}
