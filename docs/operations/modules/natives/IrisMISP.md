# Module IRIS MISP 

!!! tip "*Introduced in IRIS v1.4.0*"  


This module offers an interface with MISP and IRIS to automatically enrich IOCs with MISP insight.   


The source code is available [here](https://github.com/dfir-iris/iris-misp-module). It is installed by default but needs to be configured to be enabled.  

!!! info "Note" 
    The module is in its early stage and new features will be added over time.


## Features 
Two types of enrichement mecanism are proposed : 

- **Manual** : right-click on one or more IOCs and select ``Get MISP insight``. This sends the targets IOCs to the module and insights will be fetched and applied. 
- **Automatic**:
    - On create : This automatically fetch MISP insight for newly created IOC 
    - On update : This automatically  fetch MISP insight upon updates of an IOC 


The following types of IOCs are handled by the module : 

- [x] ip-\*
- [x] domain
- [x] hashes of types md5, sha224, sha256, sha512

The insight request on an IOC not handled is simply ignored.  

The insights take the form of attributes added to the IOC. They are based on configurable templates.  

## Native IOC enrichment (IRIS 3)

Starting with module version ``1.5.0``, IrisMISP also populates the native IOC enrichment panel displayed in the IOC details view of IRIS 3. The panel reads the ``ioc.ioc_enrichment`` field and gives a concise summary of the MISP results: match status, number of matching events, highest MISP threat level, tags, classifications, event identifiers and links to the matching events.

The feature is enabled by default and can be disabled with the **Populate native IOC enrichment** module setting. The attributes generated from the report templates, including the full raw MISP results, remain available.

Enrichment is additive: data written by other modules is preserved and only the MISP source is replaced. A MISP match is not by itself a malicious verdict, so the MISP enrichment does not set a ``verdict``; the MISP threat level and tags are reported instead, and the verdict is left to modules that can classify the IOC.

The enrichment payload stays bounded: the raw events view is capped to 25 events, while the complete raw MISP results remain in the report attribute. For ``domain|ip`` IOCs the domain and IP results are merged into a single enrichment source.

## Configuration 
The behavior of the module can be configured as needed. Head to the `Advanced` > `Modules` > `IrisMISP` to change it.   

- **MISP configuration** : A JSON describing the MISP access. See below for the structure.  
- **Add MISP report as new IOC attribute** : If set to true, the module adds a new attribute with the MISP insight. 
- **Populate native IOC enrichment** : If set to true (default), the module also writes a summary of the MISP results to the native IOC enrichment panel of IRIS 3. The MISP Report attribute is still written. 
- **Domain report template** : Provides a right-click menu option on IOCs to trigger the MISP module on selected elements. 
- **Triggers automatically on IOC create**: If set to true, the module runs each time an IOC is created. Disabled by default. 
- **Triggers automatically on IOC update**: If set to true, the module runs each time an IOC is updated. Disabled by default. 
- **Domain report template**: Jinja2 report template for domain IOCs. Refers to the raw report to assess which fields are available. 
- **IP report template**: Jinja2 report template for IP IOCs. Refers to the raw report to assess which fields are available. 
- **Hash report template**: Jinja2 report template for hash IOCs. Refers to the raw report to assess which fields are available. 

!!! info "Upgraded deployments"
    IRIS stores the module configuration when the module is registered. On a deployment upgraded from an older module version, the stored configuration may not contain the **Populate native IOC enrichment** setting yet. The module then keeps the enabled default, so the native enrichment works without reconfiguration. The setting is exposed in the administration interface when IrisMISP is registered with this version.

### MISP configuration 
At the time, only one MISP can be added. Future version might handled more than one MISP.    
The expected structure is the following :  

```json
{
    "name": "Public_MISP", 
    "type":"public", 
    "url":["https://testmisp"],
    "key":["<apikey>"], 
    "ssl":[false]
}
```