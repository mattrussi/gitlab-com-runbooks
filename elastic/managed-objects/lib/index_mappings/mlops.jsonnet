{
  properties: {
    '@timestamp': {
      type: 'date',
    },
    attributes: {
      properties: {
        logging: {
          properties: {
            googleapis: {
              properties: {
                'com/timestamp': {
                  type: 'date',
                },
              },
            },
          },
        },
      },
    },
    host: {
      properties: {
        name: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
      },
    },
    json: {
      properties: {
        httpRequest: {
          properties: {
            latency: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            protocol: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            referer: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            remoteIp: {
              type: 'ip',
              store: true,
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            requestMethod: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            requestSize: {
              type: 'long',
            },
            requestUrl: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            responseSize: {
              type: 'long',
            },
            serverIp: {
              type: 'ip',
              store: true,
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            status: {
              type: 'long',
            },
            userAgent: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
          },
        },
        insertId: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        jsonPayload: {
          properties: {
            accepts: {
              type: 'long',
            },
            auth_duration_s: {
              type: 'float',
            },
            auth_error_details: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            backtrace: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            blocked: {
              type: 'boolean',
            },
            client_ip: {
              type: 'ip',
              store: true,
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            client_port: {
              type: 'long',
            },
            correlation_id: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            cpu_s: {
              type: 'long',
            },
            discarded: {
              type: 'boolean',
            },
            duration_s: {
              type: 'float',
            },
            editor_lang: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            error_codes: {
              type: 'long',
            },
            errors: {
              type: 'long',
            },
            exception: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            exp: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            experiments: {
              properties: {
                name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                variant: {
                  type: 'long',
                },
              },
            },
            extra: {
              properties: {
                model_engine: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                model_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
            gitlab_global_user_id: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            gitlab_host_name: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            gitlab_instance_id: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            gitlab_realm: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            gitlab_saas_duo_pro_namespace_ids: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            gitlab_saas_namespace_ids: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            http_exception_details: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            http_version: {
              type: 'text',
            },
            inference_duration_s: {
              type: 'float',
            },
            lang: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            level: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            logger: {
              type: 'text',
            },
            message: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            meta: {
              properties: {
                feature_category: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
            method: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            model_engine: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            model_exception_message: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            model_exception_status_code: {
              type: 'long',
            },
            model_name: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            model_output_length: {
              type: 'long',
            },
            model_output_length_stripped: {
              type: 'long',
            },
            model_output_score: {
              type: 'long',
            },
            path: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            pid: {
              type: 'long',
            },
            post_processing_duration_s: {
              type: 'float',
            },
            prompt_length: {
              type: 'long',
            },
            prompt_length_stripped: {
              type: 'long',
            },
            prompt_symbols: {
              properties: {
                block_comment: {
                  type: 'long',
                },
                class: {
                  type: 'long',
                },
                class_declaration: {
                  type: 'long',
                },
                class_definition: {
                  type: 'long',
                },
                comment: {
                  type: 'long',
                },
                function_declaration: {
                  type: 'long',
                },
                function_definition: {
                  type: 'long',
                },
                function_item: {
                  type: 'long',
                },
                generator_function_declaration: {
                  type: 'long',
                },
                import_declaration: {
                  type: 'long',
                },
                import_header: {
                  type: 'long',
                },
                import_statement: {
                  type: 'long',
                },
                line_comment: {
                  type: 'long',
                },
                module: {
                  type: 'long',
                },
                multiline_comment: {
                  type: 'long',
                },
                namespace_use_declaration: {
                  type: 'long',
                },
                preproc_include: {
                  type: 'long',
                },
                require: {
                  type: 'long',
                },
                use_declaration: {
                  type: 'long',
                },
                using_directive: {
                  type: 'long',
                },
              },
            },
            requests: {
              type: 'long',
            },
            response_body: {
              type: 'text',
            },
            stacktrace: {
              properties: {
                lines: {
                  properties: {
                    filename: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    line: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    lineno: {
                      type: 'long',
                    },
                    name: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
                thread_id: {
                  type: 'long',
                },
              },
            },
            stage: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            status_code: {
              type: 'long',
            },
            suffix_length: {
              type: 'long',
            },
            threads_count: {
              type: 'long',
            },
            timestamp: {
              type: 'date',
            },
            type: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            url: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            user_agent: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            variants: {
              type: 'long',
            },
          },
        },
        labels: {
          properties: {
            container_name: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            instanceId: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
          },
        },
        logName: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        protoPayload: {
          properties: {
            '@type': {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            authenticationInfo: {
              properties: {
                principalEmail: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                principalSubject: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                serviceAccountDelegationInfo: {
                  properties: {
                    principalSubject: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
              },
            },
            authorizationInfo: {
              properties: {
                granted: {
                  type: 'boolean',
                },
                permission: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                resource: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                resourceAttributes: {
                  type: 'object',
                },
              },
            },
            methodName: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            requestMetadata: {
              properties: {
                callerIp: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                callerNetwork: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                callerSuppliedUserAgent: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                destinationAttributes: {
                  type: 'object',
                },
                requestAttributes: {
                  properties: {
                    auth: {
                      type: 'object',
                    },
                    time: {
                      type: 'date',
                    },
                  },
                },
              },
            },
            resourceLocation: {
              properties: {
                currentLocations: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
            resourceName: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            response: {
              properties: {
                '@type': {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                apiVersion: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                kind: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                metadata: {
                  properties: {
                    annotations: {
                      properties: {
                        autoscaling: {
                          properties: {
                            knative: {
                              properties: {
                                'dev/maxScale': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'dev/minScale': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        run: {
                          properties: {
                            googleapis: {
                              properties: {
                                'com/container-dependencies': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'com/cpu-throttling': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'com/ingress': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'com/ingress-status': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'com/launch-stage': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'com/operation-id': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'com/sessionAffinity': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'com/startup-cpu-boost': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        serving: {
                          properties: {
                            knative: {
                              properties: {
                                'dev/creator': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'dev/lastModifier': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    creationTimestamp: {
                      type: 'date',
                    },
                    generation: {
                      type: 'long',
                    },
                    labels: {
                      properties: {
                        cloud: {
                          properties: {
                            googleapis: {
                              properties: {
                                'com/location': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        gl_dept: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        gl_dept_group: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        gl_env_name: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        gl_env_type: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        gl_owner_email_handle: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        gl_product_category: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        gl_realm: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        run: {
                          properties: {
                            googleapis: {
                              properties: {
                                'com/startupProbeType': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        serving: {
                          properties: {
                            knative: {
                              properties: {
                                'dev/configuration': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'dev/configurationGeneration': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'dev/route': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'dev/service': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'dev/serviceUid': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    name: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    namespace: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    ownerReferences: {
                      properties: {
                        apiVersion: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        blockOwnerDeletion: {
                          type: 'boolean',
                        },
                        controller: {
                          type: 'boolean',
                        },
                        kind: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        name: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        uid: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    resourceVersion: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    selfLink: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    uid: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
                spec: {
                  properties: {
                    containerConcurrency: {
                      type: 'long',
                    },
                    containers: {
                      properties: {
                        env: {
                          properties: {
                            name: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            value: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            valueFrom: {
                              properties: {
                                secretKeyRef: {
                                  properties: {
                                    key: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                    name: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        image: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        livenessProbe: {
                          properties: {
                            failureThreshold: {
                              type: 'long',
                            },
                            httpGet: {
                              properties: {
                                path: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                port: {
                                  type: 'long',
                                },
                              },
                            },
                            periodSeconds: {
                              type: 'long',
                            },
                            timeoutSeconds: {
                              type: 'long',
                            },
                          },
                        },
                        name: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        ports: {
                          properties: {
                            containerPort: {
                              type: 'long',
                            },
                            name: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                          },
                        },
                        resources: {
                          properties: {
                            limits: {
                              properties: {
                                cpu: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                memory: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        startupProbe: {
                          properties: {
                            failureThreshold: {
                              type: 'long',
                            },
                            httpGet: {
                              properties: {
                                path: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                port: {
                                  type: 'long',
                                },
                              },
                            },
                            periodSeconds: {
                              type: 'long',
                            },
                            tcpSocket: {
                              properties: {
                                port: {
                                  type: 'long',
                                },
                              },
                            },
                            timeoutSeconds: {
                              type: 'long',
                            },
                          },
                        },
                        volumeMounts: {
                          properties: {
                            mountPath: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            name: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    serviceAccountName: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    template: {
                      properties: {
                        metadata: {
                          properties: {
                            annotations: {
                              properties: {
                                autoscaling: {
                                  properties: {
                                    knative: {
                                      properties: {
                                        'dev/maxScale': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        'dev/minScale': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                                run: {
                                  properties: {
                                    googleapis: {
                                      properties: {
                                        'com/container-dependencies': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        'com/cpu-throttling': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        'com/sessionAffinity': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        'com/startup-cpu-boost': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                            labels: {
                              properties: {
                                run: {
                                  properties: {
                                    googleapis: {
                                      properties: {
                                        'com/startupProbeType': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                            name: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                          },
                        },
                        spec: {
                          properties: {
                            containerConcurrency: {
                              type: 'long',
                            },
                            containers: {
                              properties: {
                                env: {
                                  properties: {
                                    name: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                    value: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                    valueFrom: {
                                      properties: {
                                        secretKeyRef: {
                                          properties: {
                                            key: {
                                              type: 'text',
                                              fields: {
                                                keyword: {
                                                  type: 'keyword',
                                                  ignore_above: 256,
                                                },
                                              },
                                            },
                                            name: {
                                              type: 'text',
                                              fields: {
                                                keyword: {
                                                  type: 'keyword',
                                                  ignore_above: 256,
                                                },
                                              },
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                                image: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                livenessProbe: {
                                  properties: {
                                    failureThreshold: {
                                      type: 'long',
                                    },
                                    httpGet: {
                                      properties: {
                                        path: {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        port: {
                                          type: 'long',
                                        },
                                      },
                                    },
                                    periodSeconds: {
                                      type: 'long',
                                    },
                                    timeoutSeconds: {
                                      type: 'long',
                                    },
                                  },
                                },
                                name: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                ports: {
                                  properties: {
                                    containerPort: {
                                      type: 'long',
                                    },
                                    name: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                                resources: {
                                  properties: {
                                    limits: {
                                      properties: {
                                        cpu: {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        memory: {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                                startupProbe: {
                                  properties: {
                                    failureThreshold: {
                                      type: 'long',
                                    },
                                    httpGet: {
                                      properties: {
                                        path: {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        port: {
                                          type: 'long',
                                        },
                                      },
                                    },
                                    periodSeconds: {
                                      type: 'long',
                                    },
                                    tcpSocket: {
                                      properties: {
                                        port: {
                                          type: 'long',
                                        },
                                      },
                                    },
                                    timeoutSeconds: {
                                      type: 'long',
                                    },
                                  },
                                },
                                volumeMounts: {
                                  properties: {
                                    mountPath: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                    name: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                            serviceAccountName: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            timeoutSeconds: {
                              type: 'long',
                            },
                            volumes: {
                              properties: {
                                emptyDir: {
                                  properties: {
                                    medium: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                    sizeLimit: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                                name: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                secret: {
                                  properties: {
                                    items: {
                                      properties: {
                                        key: {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        mode: {
                                          type: 'long',
                                        },
                                        path: {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                    secretName: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    timeoutSeconds: {
                      type: 'long',
                    },
                    traffic: {
                      properties: {
                        percent: {
                          type: 'long',
                        },
                        revisionName: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        tag: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    volumes: {
                      properties: {
                        emptyDir: {
                          properties: {
                            medium: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            sizeLimit: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                          },
                        },
                        name: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        secret: {
                          properties: {
                            items: {
                              properties: {
                                key: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                mode: {
                                  type: 'long',
                                },
                                path: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                            secretName: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                  },
                },
                status: {
                  properties: {
                    address: {
                      properties: {
                        url: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    conditions: {
                      properties: {
                        lastTransitionTime: {
                          type: 'date',
                        },
                        severity: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        status: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        type: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    containerStatuses: {
                      properties: {
                        imageDigest: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        name: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    desiredReplicas: {
                      type: 'long',
                    },
                    latestCreatedRevisionName: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    latestReadyRevisionName: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    logUrl: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    observedGeneration: {
                      type: 'long',
                    },
                    traffic: {
                      properties: {
                        percent: {
                          type: 'long',
                        },
                        revisionName: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        tag: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        url: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    url: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
              },
            },
            serviceName: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            status: {
              properties: {
                message: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
          },
        },
        receiveTimestamp: {
          type: 'date',
        },
        resource: {
          properties: {
            labels: {
              properties: {
                cluster_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                configuration_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                container_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                location: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                namespace_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                pod_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                project_id: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                revision_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                service_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
            type: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
          },
        },
        severity: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        spanId: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        textPayload: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        timestamp: {
          type: 'date',
        },
        trace: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        traceSampled: {
          type: 'boolean',
        },
      },
    },
    publish_time: {
      type: 'date',
    },
    type: {
      type: 'text',
      fields: {
        keyword: {
          type: 'keyword',
          ignore_above: 256,
        },
      },
    },
  },
}
