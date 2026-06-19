/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

variable "metadata" {
  type = any
}

/*----------------------------------------------------------------------*/
/* COGNITO | Variable Definition                                        */
/*----------------------------------------------------------------------*/

variable "cognito_parameters" {
  type        = any
  description = "Map of Cognito user pool configurations keyed by pool name."
  default     = {}
}

variable "cognito_defaults" {
  type        = any
  description = "Default values merged into each entry of cognito_parameters."
  default     = {}
}
