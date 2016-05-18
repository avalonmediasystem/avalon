
$(document).ready(function(){
	
	// find interesting elements
	var value = $("#media_object_license_type");
	var license_list = value.next("ul").children();
	var custom_license_div = $("label[for='media_object_access_restrictions_rights']").closest("div");
	var licenseOnLoad = value.attr("value");

	// make sure custom entry area is shown or hidden based on initial populated license type
	if (licenseOnLoad == "User_Defined_Rights_Statement") {
		custom_license_div.show();
	} else {
		custom_license_div.hide();
	}

	// scan license descriptions from hidden lists to populate from controlled vocabulary
	var descriptions = $(".license_description");
	var descriptionList = {};
	descriptions.each(function(index) {
		var description = $(this).children("a").text();
		var type = $(this).children("span").text();
		//console.log(type + " ::: " description);
		descriptionList[type] = description;
	});

	// make the license description display area disabled from interaction/input
	$("#typed_textarea_access_restrictions_license_0").attr("readonly","readonly");
	// display the description for the initial license selection
	$("#typed_textarea_access_restrictions_license_0").text(descriptionList[licenseOnLoad]);
	
	
	// attach click event to each list item (license option in dropdown)
	license_list.each(function(index) {

		$(this).on("click", function(){

			var license = $(this).children("span").text();
			$("#typed_textarea_access_restrictions_license_0").text(descriptionList[license]);
			
 			// for a custom license, unhide the custom entry area
			if (license == "User_Defined_Rights_Statement") {
				custom_license_div.fadeIn();
			} else {
				custom_license_div.fadeOut();
			}
			//alert(license);
			
		});
	});

	// deposit agreement checkbox
	var checkbox = $("#agreement_checkbox");
	var saveButton = $("input[value='Save']");
	var saveAndContinueButton = $("input[value='Save and continue']");
	checkbox.attr("checked",false);
	saveButton.attr("disabled",true);
	saveAndContinueButton.attr("disabled",true);
	console.log(saveButton);
	
	var cb = checkbox.change(function() {
		var t = $(this).is(":checked");
		if ($(this).is(":checked")) {
			console.log("checked!");
			saveButton.attr("disabled",false);
			saveAndContinueButton.attr("disabled",false);
		}
		else {
			console.log("unchecked!");
			saveButton.attr("disabled",true);
			saveAndContinueButton.attr("disabled",true);
		}
	});

	// modal display for the deposit agreement text
});
