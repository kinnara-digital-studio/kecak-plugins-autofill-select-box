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
import org.joget.apps.datalist.model.DataListBinderDefault;
import org.joget.apps.datalist.model.DataListCollection;
import org.joget.apps.datalist.model.DataListFilterQueryObject;
import org.joget.apps.form.lib.SelectBox;
import org.joget.apps.form.model.FormData;
import org.joget.apps.form.model.FormLoadBinder;
import org.joget.apps.form.model.FormRow;
import org.joget.apps.form.service.FormUtil;
import org.joget.commons.util.LogUtil;
import org.joget.commons.util.SecurityUtil;
import org.joget.plugin.base.PluginManager;
import org.joget.plugin.base.PluginWebSupport;
import org.joget.plugin.property.model.PropertyEditable;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class AutofillSelectBox extends SelectBox implements PluginWebSupport{

	private final static String PARAMETER_ID = "id";
	
	public void webService(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		
		if("POST".equals(request.getMethod())) {
			try {			
				JSONObject body = constructRequestBody(request);
				
				PluginManager pluginManager = (PluginManager) AppUtil.getApplicationContext().getBean("pluginManager");
				
				// build enhancement-plugin
				DataListBinderDefault loadBinder = (DataListBinderDefault) pluginManager.getPlugin(body.getString("className"));
				
				if(loadBinder != null) {
					Map<String, Object> binderProperties = jsonToMap(body.getJSONObject("properties"));
					
					// set enhancement-plugin properties
					if(binderProperties != null)
						loadBinder.setProperties(binderProperties);
					
					String primaryKey = request.getParameter(PARAMETER_ID);					
					DataListFilterQueryObject filter = new DataListFilterQueryObject();
					filter.setQuery(loadBinder.getPrimaryKeyColumnName() + " = ?");
					filter.setOperator("AND");
					filter.setValues(new String[] { primaryKey });
					DataListFilterQueryObject[] filterQueryObjects = { filter };
					DataListCollection data = loadBinder.getData(null, loadBinder.getProperties(), filterQueryObjects, null, null, null, 1);	
					response.setStatus(HttpServletResponse.SC_OK);
					response.getWriter().write(formRowSetToJson(data).toString());
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
        return AppUtil.readPluginResource(getClass().getName(), "/properties/autofillFormElements.json", new String[]{selectForm, encryption}, true, "message/form/SelectBox");
	}

	@Override
	public String getName() {
		return "Autofill SelectBox";
	}

	@Override
	public String getVersion() {
		return "1.0.0";
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
        String template = "autofillFormElements.ftl";

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
        
        try {
			dataModel.put("autofillLoadBinder", FormUtil.generatePropertyJsonObject((Map<String, Object>)getProperty("autofillLoadBinder")));
		} catch (JSONException e) {
			LogUtil.warn(getClassName(), "Load Binder properties error");
			e.printStackTrace();
		}
        
        String html = FormUtil.generateElementHtml(this, formData, template, dataModel);
        return html;
	}
	
	private String getTableFromForm(String formDefId) {
		// proceed without cache    	
        AppDefinition appDef = AppUtil.getCurrentAppDefinition();
        if (appDef != null && formDefId != null && !formDefId.isEmpty()) {
            FormDefinitionDao formDefinitionDao = (FormDefinitionDao)AppUtil.getApplicationContext().getBean("formDefinitionDao");
            FormDefinition formDef = formDefinitionDao.loadById(formDefId, appDef);
            if (formDef != null) {
            	return formDef.getTableName();
            }
        }
        
        return "";
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
	
	private JSONArray formRowSetToJson(DataListCollection<FormRow> data) {
		JSONArray result = new JSONArray();
		if(data != null) {		
			for(FormRow row : data) {
				result.put(row);
			}
		}
		return result;
	}

	interface AutofillLoadBinder extends FormLoadBinder, PropertyEditable {
	}
}
