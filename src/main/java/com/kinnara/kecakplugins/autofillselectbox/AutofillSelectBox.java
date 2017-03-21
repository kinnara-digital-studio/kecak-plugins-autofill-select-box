package com.kinnara.kecakplugins.autofillselectbox;

import java.io.BufferedReader;
import java.io.IOException;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.joget.apps.app.dao.FormDefinitionDao;
import org.joget.apps.app.model.AppDefinition;
import org.joget.apps.app.model.FormDefinition;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.form.lib.CheckBox;
import org.joget.apps.form.lib.Radio;
import org.joget.apps.form.lib.SelectBox;
import org.joget.apps.form.model.Element;
import org.joget.apps.form.model.Form;
import org.joget.apps.form.model.FormData;
import org.joget.apps.form.model.FormLoadBinder;
import org.joget.apps.form.model.FormRow;
import org.joget.apps.form.model.FormRowSet;
import org.joget.apps.form.service.FormService;
import org.joget.apps.form.service.FormUtil;
import org.joget.commons.util.LogUtil;
import org.joget.commons.util.SecurityUtil;
import org.joget.plugin.base.PluginManager;
import org.joget.plugin.base.PluginWebSupport;
import org.joget.plugin.property.model.PropertyEditable;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.springframework.context.ApplicationContext;

public class AutofillSelectBox extends SelectBox implements PluginWebSupport{
	private final static String PARAMETER_ID = "id";
	
	public void webService(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		
		
		if("POST".equals(request.getMethod())) {
			ApplicationContext appContext = AppUtil.getApplicationContext();
			
			try {			
				JSONObject body = constructRequestBody(request);
				
				JSONObject autofillLoadBinder = body.getJSONObject("autofillLoadBinder");
				JSONObject autofillForm = body.getJSONObject("autofillForm");
						
				PluginManager pluginManager = (PluginManager) appContext.getBean("pluginManager");
				
				// build enhancement-plugin
				Object loadBinder = pluginManager
						.getPlugin(autofillLoadBinder.getString("className"));
				
				// build form
				FormService formService = (FormService) appContext.getBean("formService");
				Form form = (Form)formService.createElementFromJson(autofillForm.toString());
								
				if(loadBinder != null) {
					Map<String, Object> binderProperties = jsonToMap(autofillLoadBinder.getJSONObject("properties"));
					
					// set enhancement-plugin properties
					if(binderProperties != null) {
						((PropertyEditable)loadBinder).setProperties(binderProperties);
						form.setLoadBinder((FormLoadBinder)loadBinder);
					}
					
					String primaryKey = request.getParameter(PARAMETER_ID);
					JSONArray data = loadFormData(form, primaryKey);
	
					response.setStatus(HttpServletResponse.SC_OK);
					response.getWriter().write(data.toString());
				} else {
					response.sendError(HttpServletResponse.SC_NOT_IMPLEMENTED);	
				}
				
			} catch (JSONException e) {
				e.printStackTrace();
				response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			}
		} else {
			response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
		}
	}
	
	@Override
	public String getLabel() {
		return getName();
	}

	@Override
	public String getClassName() {
		return getClass().getName();
	}

	@Override
	public String getPropertyOptions() {
		String encryption = "";
        if (SecurityUtil.getDataEncryption() != null) {
            encryption = ",{name : 'encryption', label : '@@form.textfield.encryption@@', type : 'checkbox', value : 'false', ";
            encryption += "options : [{value : 'true', label : '' }]}";
        }
        
        String selectForm = null;
        AppDefinition appDef = AppUtil.getCurrentAppDefinition();
        if (appDef != null) {
            String formJsonUrl = "[CONTEXT_PATH]/web/json/console/app/" + appDef.getId() + "/" + appDef.getVersion() + "/forms/options";
            selectForm = "{name:'selectForm',label:'Form',type:'selectbox',options_ajax:'" + formJsonUrl + "',required : 'True'}";
        } else {
            selectForm = "{name:'selectForm',label:'Form',type:'textfield',required : 'True'}";
        }
        return AppUtil.readPluginResource(getClass().getName(), "/properties/AutofillFormElements.json", new String[]{selectForm, encryption}, true, "message/form/SelectBox");
	}

	@Override
	public String getName() {
		return "Autofill SelectBox";
	}

	@Override
	public String getVersion() {
		return "1.1.0";
	}

	@Override
	public String getDescription() {
		return "Kecak - " + getName();
	}

	@Override
	public String getFormBuilderCategory() {
		return "Kecak Enterprise";
    }

	@Override
	public String renderTemplate(FormData formData, Map dataModel) {
        String template = "AutofillFormElements.ftl";

        dynamicOptions(formData);

        // set value
        String[] valueArray = FormUtil.getElementPropertyValues(this, formData);
        List<String> values = Arrays.asList(valueArray);
        dataModel.put("values", values);

        // set options
        @SuppressWarnings("rawtypes")
		Collection<Map> optionMap = getOptionMap(formData);
        dataModel.put("options", optionMap);
        dataModel.put("className", getClassName());
        dataModel.put("keyField", PARAMETER_ID);
        
        Map<String, String> fieldTypes = new HashMap<String, String>();
        getFieldTypes(FormUtil.findRootForm(this), fieldTypes);
        dataModel.put("fieldTypes", fieldTypes);
                
        try {
        	Map<String, Object> autofillLoadBinder = (Map<String, Object>)getProperty("autofillLoadBinder");
        	if(autofillLoadBinder != null)
        		dataModel.put("autofillLoadBinder", FormUtil.generatePropertyJsonObject(autofillLoadBinder));
        	
			dataModel.put("autofillForm", FormUtil.generateElementJson(FormUtil.findRootForm(this)));
		} catch (Exception e) {
			LogUtil.warn(getClassName(), "Load Binder properties error");
			e.printStackTrace();
		}
        
        String html = FormUtil.generateElementHtml(this, formData, template, dataModel);
        return html;
	}
	
	private void getFieldTypes(Element element, Map<String, String> types) {
		String id = element.getPropertyString(FormUtil.PROPERTY_ID);
		
		if(id != null && !id.isEmpty()) {
			if(element instanceof CheckBox)
				types.put(id, "CHECK_BOXES");
			else if(element instanceof Radio)
				types.put(id, "RADIOS");
			else if(element.getClassName().matches(".+Grid$"))
				types.put(id, "GRIDS");
			else
				types.put(id, "OTHERS");
		}
		
		for(Element child : element.getChildren()) {
			getFieldTypes(child, types);
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
		StringBuilder sb = new StringBuilder();
		BufferedReader bf = request.getReader();
		String line;
		while((line = bf.readLine()) != null) {
			sb.append(line);
		}
		
		return new JSONObject(sb.toString());
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
	
	private JSONArray loadFormData(Form form, String primaryKey) {		
		ApplicationContext appContext = AppUtil.getApplicationContext();
		FormService formService = (FormService) appContext.getBean("formService");
		FormData formData = new FormData();
		formData.setPrimaryKeyValue(primaryKey);
		formData = formService.executeFormLoadBinders(form, formData);
		FormRowSet rowSet = formData.getLoadBinderData(form);		
		return formRowSetToJson(rowSet);
	}
}
