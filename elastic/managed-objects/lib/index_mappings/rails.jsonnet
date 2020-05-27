{
  properties: {
    '@timestamp': {
      type: 'date',
    },
    ecs: {
      properties: {
        version: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
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
        acme_error: {
          properties: {
            detail: {
              type: 'text',
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
            type: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
          },
        },
        action: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        add: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        allowed: {
          type: 'boolean',
        },
        api_error: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        app_id: {
          type: 'long',
        },
        app_name: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        application: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        as: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        author_id: {
          type: 'float',
        },
        author_name: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        authorized_actions: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        cf_ray: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        cf_request_id: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        change: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        class: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        class_name: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        client_url: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        cluster_id: {
          type: 'long',
        },
        complexity: {
          type: 'long',
        },
        conflict_retried: {
          type: 'long',
        },
        controller: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        correlation_id: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        count: {
          type: 'long',
        },
        cpu_s: {
          type: 'float',
        },
        current_user_id: {
          type: 'float',
        },
        custom_message: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        db: {
          type: 'float',
        },
        db_duration_s: {
          type: 'float',
        },
        db_host: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        db_port: {
          type: 'long',
        },
        depth: {
          type: 'long',
        },
        duration_s: {
          type: 'float',
        },
        entity_id: {
          type: 'float',
        },
        entity_path: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        entity_type: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        env: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        environment: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        'error': {
          properties: {
            exception_backtrace: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            exception_class: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            exception_message: {
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
        etag_route: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        event: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        exception: {
          properties: {
            backtrace: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            class: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
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
          },
        },
        execution_count: {
          type: 'long',
        },
        expiry_from: {
          type: 'date',
        },
        expiry_to: {
          type: 'date',
        },
        extra: {
          properties: {
            app_id: {
              type: 'long',
            },
            app_name: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            bridge_id: {
              type: 'float',
            },
            build_id: {
              type: 'float',
            },
            child: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            class: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            cluster_id: {
              type: 'long',
            },
            deployment_id: {
              type: 'float',
            },
            downstream_pipeline_id: {
              type: 'float',
            },
            'error': {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            error_code: {
              type: 'long',
            },
            errors: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            exportable_id: {
              type: 'float',
            },
            exportable_path: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            file_name: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            group_ids: {
              type: 'float',
            },
            iid: {
              type: 'long',
            },
            import_jid: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            importer: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            issue_url: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            job_id: {
              type: 'float',
            },
            merge_request: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            merge_request_id: {
              type: 'float',
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
            namespace_id: {
              type: 'float',
            },
            new_name: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            old_name: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            parent: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
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
            pipeline_id: {
              type: 'float',
            },
            plan: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            preloaded: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            project_id: {
              type: 'float',
            },
            project_ids: {
              type: 'float',
            },
            project_path: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            raw_response: {
              type: 'object',
              enabled: false,
            },
            reason: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            relation_index: {
              type: 'long',
            },
            relation_key: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            request: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            response: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            retry_count: {
              type: 'long',
            },
            save_message_on_model: {
              type: 'boolean',
            },
            service: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            sha: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            sidekiq: {
              properties: {
                args: {
                  type: 'text',
                },
                backtrace: {
                  type: 'long',
                },
                class: {
                  type: 'keyword',
                  ignore_above: 256,
                  store: true,
                },
                correlation_id: {
                  type: 'keyword',
                  ignore_above: 256,
                  store: true,
                },
                created_at: {
                  type: 'float',
                },
                enqueued_at: {
                  type: 'float',
                },
                error_backtrace: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                error_class: {
                  type: 'keyword',
                  ignore_above: 256,
                  store: true,
                },
                error_message: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                failed_at: {
                  type: 'float',
                },
                interrupted_count: {
                  type: 'long',
                },
                jid: {
                  type: 'keyword',
                  ignore_above: 256,
                  store: true,
                },
                memory_killer_max_memory_growth_kb: {
                  type: 'long',
                },
                memory_killer_memory_growth_kb: {
                  type: 'long',
                },
                meta: {
                  properties: {
                    caller_id: {
                      type: 'keyword',
                      ignore_above: 256,
                      store: true,
                    },
                    project: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    related_class: {
                      type: 'keyword',
                      ignore_above: 256,
                      store: true,
                    },
                    root_namespace: {
                      type: 'keyword',
                      ignore_above: 256,
                      store: true,
                    },
                    user: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                queue: {
                  type: 'keyword',
                  ignore_above: 256,
                  store: true,
                },
                queue_namespace: {
                  type: 'keyword',
                  ignore_above: 256,
                  store: true,
                },
                retried_at: {
                  type: 'float',
                },
                retry: {
                  type: 'text',
                },
                retry_count: {
                  type: 'long',
                },
                status_expiration: {
                  type: 'long',
                },
              },
            },
            source: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            stage: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            storage: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            subject_id: {
              type: 'float',
            },
            trace: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            type: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
          },
        },
        filtered: {
          properties: {
            ability: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            class_name: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            id: {
              type: 'float',
            },
          },
        },
        format: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        fqdn: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        from: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        gitaly_calls: {
          type: 'long',
        },
        gitaly_duration_s: {
          type: 'float',
        },
        group_full_path: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        group_id: {
          type: 'float',
        },
        group_ids: {
          type: 'float',
        },
        group_name: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        host: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        host_list_length: {
          type: 'long',
        },
        hostname: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        iid: {
          type: 'long',
        },
        inline_comments_count: {
          type: 'long',
        },
        integration: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        ip_address: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        iterations: {
          type: 'long',
        },
        jira_response: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        lfs_objects_linked_count: {
          type: 'long',
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
        merge_access_levels: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        merge_event_found: {
          type: 'boolean',
        },
        merge_request: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        merge_request_id: {
          type: 'float',
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
            caller_id: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            project: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            root_namespace: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            subscription_plan: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            user: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        method: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        namespace: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        next_execution: {
          type: 'long',
        },
        pages_domain: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        params: {
          properties: {
            key: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
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
          },
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
        project_id: {
          type: 'float',
        },
        project_ids: {
          type: 'float',
        },
        project_path: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        push_access_levels: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        query: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        query_string: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        queue_duration_s: {
          type: 'float',
        },
        redis_calls: {
          type: 'long',
        },
        redis_duration_s: {
          type: 'float',
        },
        redis_read_bytes: {
          type: 'long',
        },
        redis_write_bytes: {
          type: 'long',
        },
        remote_ip: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        remove: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        request_method: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        requested_actions: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        requested_project_path: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        response: {
          type: 'object',
          enabled: false,
        },
        route: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        save_message_on_model: {
          type: 'boolean',
        },
        scope_type: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        service: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        service_class: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        severity: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        shard: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        stage: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        standalone_pr_comments: {
          type: 'long',
        },
        status: {
          type: 'long',
        },
        status_code: {
          type: 'long',
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
        tags: {
          properties: {
            correlation_id: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
            locale: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
          },
        },
        target_details: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        target_id: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        target_type: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        tier: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        time: {
          type: 'date',
        },
        to: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        tracked_items_encoded: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        type: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        ua: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        unmatched_line: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        update: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        user: {
          properties: {
            email: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            id: {
              type: 'float',
            },
            ip_address: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            username: {
              type: 'keyword',
              ignore_above: 256,
              store: true,
            },
          },
        },
        user_id: {
          type: 'long',
        },
        username: {
          type: 'keyword',
          ignore_above: 256,
          store: true,
        },
        variables: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        view_duration_s: {
          type: 'float',
        },
        with: {
          type: 'keyword',
          ignore_above: 256,
        },
      },
    },
    message_id: {
      type: 'keyword',
      ignore_above: 256,
      store: true,
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
