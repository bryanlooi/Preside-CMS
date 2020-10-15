/**
 *
 * @expressionCategory formbuilder
  * @expressionContexts user
 * @feature            websiteusers
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";
	property name="formBuilderService"         inject="formBuilderService";
	property name="formBuilderFilterService"   inject="formBuilderFilterService";

	/**
	 * @question.fieldtype      formbuilderQuestion
	 * @question.object         formbuilder_question
	 * @question.item_type      "starRating"
	 * @value.fieldtype         formbuilderQuestionStarRatingValue
	 *
	 */
	private boolean function evaluateExpression(
		  required string  question
		, required numeric value
		,          string  _numericOperator = "eq"
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return false;
		}

		var filter = prepareFilters( argumentCollection = arguments	) ;

		return formBuilderFilterService.evaluateQuestionUserLatestResponseMatch(
			  argumentCollection = arguments
			, userId             = userId
			, formId             = payload.formId ?: ""
			, submissionId       = payload.submissionId ?: ""
			, extraFilters       = filter
		);
	}

	/**
	 * @objects website_user
	 */
	private array function prepareFilters(
		  required string  question
		, required numeric value
		,          string  _numericOperator = "eq"
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		return formBuilderFilterService.prepareFilterForUserLatestResponseToNumberField( argumentCollection=arguments );
	}

}
