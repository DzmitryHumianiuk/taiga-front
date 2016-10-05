###
# Copyright (C) 2014-2016 Andrey Antukh <niwi@niwi.nz>
# Copyright (C) 2014-2016 Jesús Espino Garcia <jespinog@gmail.com>
# Copyright (C) 2014-2016 David Barragán Merino <bameda@dbarragan.com>
# Copyright (C) 2014-2016 Alejandro Alonso <alejandro.alonso@kaleidos.net>
# Copyright (C) 2014-2016 Juan Francisco Alcántara <juanfran.alcantara@kaleidos.net>
# Copyright (C) 2014-2016 Xavi Julian <xavier.julian@kaleidos.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# File: modules/common/components.coffee
###

taiga = @.taiga
bindOnce = @.taiga.bindOnce

module = angular.module("taigaCommon")


#############################################################################
## Date Range Directive (used mainly for sprint date range)
#############################################################################

DateRangeDirective = ($translate) ->
    renderRange = ($el, first, second) ->
        prettyDate = $translate.instant("BACKLOG.SPRINTS.DATE")
        initDate = moment(first).format(prettyDate)
        endDate = moment(second).format(prettyDate)
        $el.html("#{initDate}-#{endDate}")

    link = ($scope, $el, $attrs) ->
        [first, second] = $attrs.tgDateRange.split(",")

        bindOnce $scope, first, (valFirst) ->
            bindOnce $scope, second, (valSecond) ->
                renderRange($el, valFirst, valSecond)

    return {link:link}

module.directive("tgDateRange", ["$translate", DateRangeDirective])


#############################################################################
## Date Selector Directive (using pikaday)
#############################################################################

DateSelectorDirective = ($rootscope, datePickerConfigService) ->
    link = ($scope, $el, $attrs, $model) ->
        selectedDate = null

        initialize = () ->
            datePickerConfig = datePickerConfigService.get()

            _.merge(datePickerConfig, {
                field: $el[0]
                onSelect: (date) =>
                    selectedDate = date
                onOpen: =>
                    $el.picker.setDate(selectedDate) if selectedDate?
            })

            $el.picker = new Pikaday(datePickerConfig)

        unbind = $rootscope.$on "$translateChangeEnd", (ctx) => initialize()

        $scope.$watch $attrs.ngModel, (val) ->
            initialize() if val? and not $el.picker
            $el.picker.setDate(val) if val?

        $scope.$on "$destroy", ->
            $el.off()
            unbind()

    return {
        link: link
        require: "ngModel"
    }

module.directive("tgDateSelector", ["$rootScope", "tgDatePickerConfigService", DateSelectorDirective])


#############################################################################
## Sprint Progress Bar Directive
#############################################################################

SprintProgressBarDirective = ->
    renderProgress = ($el, percentage, visual_percentage) ->
        if $el.hasClass(".current-progress")
            $el.css("width", "#{percentage}%")
        else
            $el.find(".current-progress").css("width", "#{visual_percentage}%")
            $el.find(".number").html("#{percentage} %")

    link = ($scope, $el, $attrs) ->
        bindOnce $scope, $attrs.tgSprintProgressbar, (sprint) ->
            closedPoints = sprint.closed_points
            totalPoints = sprint.total_points
            percentage = 0
            percentage = Math.round(100 * (closedPoints/totalPoints)) if totalPoints != 0
            visual_percentage = 0
            #Visual hack for .current-progress bar
            visual_percentage = Math.round(98 * (closedPoints/totalPoints)) if totalPoints != 0

            renderProgress($el, percentage, visual_percentage)

        $scope.$on "$destroy", ->
            $el.off()

    return {link: link}

module.directive("tgSprintProgressbar", SprintProgressBarDirective)


#############################################################################
## Created-by display directive
#############################################################################

CreatedByDisplayDirective = ($template, $compile, $translate, $navUrls, avatarService)->
    # Display the owner information (full name and photo) and the date of
    # creation of an object (like USs, tasks and issues).
    #
    # Example:
    #     div.us-created-by(tg-created-by-display, ng-model="us")
    #
    # Requirements:
    #   - model object must have the attributes 'created_date' and
    #     'owner'(ng-model)
    #   - scope.usersById object is required.

    link = ($scope, $el, $attrs) ->
        bindOnce $scope, $attrs.ngModel, (model) ->
            if model?

                avatar = avatarService.getAvatar(model.owner_extra_info)
                $scope.owner = model.owner_extra_info or {
                    full_name_display: $translate.instant("COMMON.EXTERNAL_USER")
                }

                $scope.owner.avatar = avatar.url
                $scope.owner.bg = avatar.bg

                $scope.url = if $scope.owner?.is_active then $navUrls.resolve("user-profile", {username: $scope.owner.username}) else ""


                $scope.date =  moment(model.created_date).format($translate.instant("COMMON.DATETIME"))

        $scope.$on "$destroy", ->
            $el.off()

    return {
        link: link
        restrict: "EA"
        require: "ngModel",
        scope: true,
        templateUrl: "common/components/created-by.html"
    }

module.directive("tgCreatedByDisplay", ["$tgTemplate", "$compile", "$translate", "$tgNavUrls", "tgAvatarService",
                                        CreatedByDisplayDirective])


UserDisplayDirective = ($template, $compile, $translate, $navUrls, avatarService)->
    # Display the user information (full name and photo).
    #
    # Example:
    #     div.creator(tg-user-display, tg-user-id="{{ user.id }}")
    #
    # Requirements:
    #   - scope.usersById object is required.

    link = ($scope, $el, $attrs) ->
        id = $attrs.tgUserId
        $scope.user = $scope.usersById[id] or {
            full_name_display: $translate.instant("COMMON.EXTERNAL_USER")
        }

        avatar = avatarService.getAvatar($scope.usersById[id] or null)

        $scope.user.avatar = avatar.url
        $scope.user.bg = avatar.bg

        $scope.url = if $scope.user.is_active then $navUrls.resolve("user-profile", {username: $scope.user.username}) else ""

        $scope.$on "$destroy", ->
            $el.off()

    return {
        link: link
        restrict: "EA"
        scope: true,
        templateUrl: "common/components/user-display.html"
    }

module.directive("tgUserDisplay", ["$tgTemplate", "$compile", "$translate", "$tgNavUrls", "tgAvatarService",
                                   UserDisplayDirective])

#############################################################################
## Watchers directive
#############################################################################

WatchersDirective = ($rootscope, $confirm, $repo, $modelTransform, $template, $compile, $translate) ->
    # You have to include a div with the tg-lb-watchers directive in the page
    # where use this directive

    link = ($scope, $el, $attrs, $model) ->
        isEditable = ->
            return $scope.project?.my_permissions?.indexOf($attrs.requiredPerm) != -1

        save = (watchers) ->
            transform = $modelTransform.save (item) ->
                item.watchers = watchers

                return item

            transform.then ->
                watchers = _.map(watchers, (watcherId) -> $scope.usersById[watcherId])
                renderWatchers(watchers)
                $rootscope.$broadcast("object:updated")

            transform.then null, ->
                $confirm.notify("error")

        deleteWatcher = (watcherIds) ->
            transform = $modelTransform.save (item) ->
                item.watchers = watcherIds

                return item

            transform.then () ->
                item = $modelTransform.getObj()
                watchers = _.map(item.watchers, (watcherId) -> $scope.usersById[watcherId])
                renderWatchers(watchers)
                $rootscope.$broadcast("object:updated")

            transform.then null, ->
                item.revert()
                $confirm.notify("error")

        renderWatchers = (watchers) ->
            $scope.watchers = watchers
            $scope.isEditable = isEditable()

        $el.on "click", ".js-delete-watcher", (event) ->
            event.preventDefault()
            return if not isEditable()
            target = angular.element(event.currentTarget)
            watcherId = target.data("watcher-id")

            title = $translate.instant("COMMON.WATCHERS.TITLE_LIGHTBOX_DELETE_WARTCHER")
            message = $scope.usersById[watcherId].full_name_display

            $confirm.askOnDelete(title, message).then (askResponse) =>
                askResponse.finish()

                watcherIds = _.clone($model.$modelValue.watchers, false)
                watcherIds = _.pull(watcherIds, watcherId)

                deleteWatcher(watcherIds)

        $scope.$on "watcher:added", (ctx, watcherId) ->
            watchers = _.clone($model.$modelValue.watchers, false)
            watchers.push(watcherId)
            watchers = _.uniq(watchers)

            save(watchers)

        $scope.$watch $attrs.ngModel, (item) ->
            return if not item?
            watchers = _.map(item.watchers, (watcherId) -> $scope.usersById[watcherId])
            watchers = _.filter watchers, (it) -> return !!it

            renderWatchers(watchers)

        $scope.$on "$destroy", ->
            $el.off()

    return {
        scope: true,
        templateUrl: "common/components/watchers.html",
        link:link,
        require:"ngModel"
    }

module.directive("tgWatchers", ["$rootScope", "$tgConfirm", "$tgRepo", "$tgQueueModelTransformation", "$tgTemplate", "$compile",
                                "$translate", WatchersDirective])


#############################################################################
## Assigned to directive
#############################################################################

AssignedToDirective = ($rootscope, $confirm, $repo, $loading, $modelTransform, $template, $translate, $compile, $currentUserService, avatarService) ->
    # You have to include a div with the tg-lb-assignedto directive in the page
    # where use this directive
    template = $template.get("common/components/assigned-to.html", true)

    link = ($scope, $el, $attrs, $model) ->
        isEditable = ->
            return $scope.project?.my_permissions?.indexOf($attrs.requiredPerm) != -1

        save = (userId) ->
            item = $model.$modelValue.clone()
            item.assigned_to = userId

            currentLoading = $loading()
                .target($el)
                .start()

            transform = $modelTransform.save (item) ->
                item.assigned_to = userId

                return item

            transform.then ->
                currentLoading.finish()
                renderAssignedTo($modelTransform.getObj())
                $rootscope.$broadcast("object:updated")

            transform.then null, ->
                $confirm.notify("error")
                currentLoading.finish()

            return transform

        renderAssignedTo = (assignedObject) ->
            avatar = avatarService.getAvatar(assignedObject?.assigned_to_extra_info)
            bg = null

            if assignedObject?.assigned_to?
                fullName = assignedObject.assigned_to_extra_info.full_name_display
                isUnassigned = false
                bg = avatar.bg
            else
                fullName = $translate.instant("COMMON.ASSIGNED_TO.ASSIGN")
                isUnassigned = true

            isIocaine = assignedObject?.is_iocaine

            ctx = {
                fullName: fullName
                avatar: avatar.url
                bg: bg
                isUnassigned: isUnassigned
                isEditable: isEditable()
                isIocaine: isIocaine
                fullNameVisible: !(isUnassigned && !$currentUserService.isAuthenticated())
            }
            html = $compile(template(ctx))($scope)
            $el.html(html)

        $el.on "click", ".user-assigned", (event) ->
            event.preventDefault()
            return if not isEditable()
            $scope.$apply ->
                $rootscope.$broadcast("assigned-to:add", $model.$modelValue)

        $el.on "click", ".assign-to-me", (event) ->
            event.preventDefault()
            return if not isEditable()
            $model.$modelValue.assigned_to = $currentUserService.getUser().get('id')
            save($currentUserService.getUser().get('id'))

        $el.on "click", ".remove-user", (event) ->
            event.preventDefault()
            return if not isEditable()
            title = $translate.instant("COMMON.ASSIGNED_TO.CONFIRM_UNASSIGNED")

            $confirm.ask(title).then (response) =>
                response.finish()
                $model.$modelValue.assigned_to  = null
                save(null)

        $scope.$on "assigned-to:added", (ctx, userId, item) ->
            return if item.id != $model.$modelValue.id

            save(userId)

        $scope.$watch $attrs.ngModel, (instance) ->
            renderAssignedTo(instance)

        $scope.$on "$destroy", ->
            $el.off()

    return {
        link:link,
        require:"ngModel"
    }

module.directive("tgAssignedTo", ["$rootScope", "$tgConfirm", "$tgRepo", "$tgLoading", "$tgQueueModelTransformation", "$tgTemplate", "$translate", "$compile","tgCurrentUserService", "tgAvatarService",
                                  AssignedToDirective])


#############################################################################
## Block Button directive
#############################################################################

BlockButtonDirective = ($rootscope, $loading, $template) ->
    template = $template.get("common/components/block-button.html")

    link = ($scope, $el, $attrs, $model) ->
        isEditable = ->
            return $scope.project.my_permissions.indexOf("modify_us") != -1

        $scope.$watch $attrs.ngModel, (item) ->
            return if not item

            if isEditable()
                $el.find('.item-block').addClass('editable')

            if item.is_blocked
                $el.find('.item-block').removeClass('is-active')
                $el.find('.item-unblock').addClass('is-active')
            else
                $el.find('.item-block').addClass('is-active')
                $el.find('.item-unblock').removeClass('is-active')

        $el.on "click", ".item-block", (event) ->
            event.preventDefault()
            $rootscope.$broadcast("block", $model.$modelValue)

        $el.on "click", ".item-unblock", (event) ->
            event.preventDefault()
            currentLoading = $loading()
                .target($el.find(".item-unblock"))
                .start()

            finish = ->
                currentLoading.finish()

            $rootscope.$broadcast("unblock", $model.$modelValue, finish)

        $scope.$on "$destroy", ->
            $el.off()

    return {
        link: link
        restrict: "EA"
        require: "ngModel"
        template: template
    }

module.directive("tgBlockButton", ["$rootScope", "$tgLoading", "$tgTemplate", BlockButtonDirective])


#############################################################################
## Delete Button directive
#############################################################################

DeleteButtonDirective = ($log, $repo, $confirm, $location, $template) ->
    template = $template.get("common/components/delete-button.html")

    link = ($scope, $el, $attrs, $model) ->
        if not $attrs.onDeleteGoToUrl
            return $log.error "DeleteButtonDirective requires on-delete-go-to-url set in scope."
        if not $attrs.onDeleteTitle
            return $log.error "DeleteButtonDirective requires on-delete-title set in scope."

        $el.on "click", ".button-delete", (event) ->
            title = $attrs.onDeleteTitle
            subtitle = $model.$modelValue.subject

            $confirm.askOnDelete(title, subtitle).then (askResponse) =>
                promise = $repo.remove($model.$modelValue)
                promise.then =>
                    askResponse.finish()
                    url = $scope.$eval($attrs.onDeleteGoToUrl)
                    $location.path(url)
                promise.then null, =>
                    askResponse.finish(false)
                    $confirm.notify("error")

        $scope.$on "$destroy", ->
            $el.off()

    return {
        link: link
        restrict: "EA"
        require: "ngModel"
        template: template
    }

module.directive("tgDeleteButton", ["$log", "$tgRepo", "$tgConfirm", "$tgLocation", "$tgTemplate", DeleteButtonDirective])


#############################################################################
## Editable subject directive
#############################################################################

EditableSubjectDirective = ($rootscope, $repo, $confirm, $loading, $modelTransform, $template) ->
    template = $template.get("common/components/editable-subject.html")

    link = ($scope, $el, $attrs, $model) ->

        $scope.$on "object:updated", () ->
            $el.find('.edit-subject').hide()
            $el.find('.view-subject').show()

        isEditable = ->
            return $scope.project.my_permissions.indexOf($attrs.requiredPerm) != -1

        save = (subject) ->
            currentLoading = $loading()
                .target($el.find('.save-container'))
                .start()

            transform = $modelTransform.save (item) ->
                item.subject  = subject

                return item

            transform.then =>
                $confirm.notify("success")
                $rootscope.$broadcast("object:updated")
                $el.find('.edit-subject').hide()
                $el.find('.view-subject').show()

            transform.then null, ->
                $confirm.notify("error")

            transform.finally ->
                currentLoading.finish()

            return transform

        $el.click ->
            return if not isEditable()
            $el.find('.edit-subject').show()
            $el.find('.view-subject').hide()
            $el.find('input').focus()

        $el.on "click", ".save", (e) ->
            e.preventDefault()

            subject = $scope.item.subject
            save(subject)

        $el.on "keyup", "input", (event) ->
            if event.keyCode == 13
                subject = $scope.item.subject
                save(subject)
            else if event.keyCode == 27
                $scope.$apply () => $model.$modelValue.revert()

                $el.find('.edit-subject').hide()
                $el.find('.view-subject').show()

        $el.find('.edit-subject').hide()

        $scope.$watch $attrs.ngModel, (value) ->
            return if not value
            $scope.item = value

            if not isEditable()
                $el.find('.view-subject .edit').remove()

        $scope.$on "$destroy", ->
            $el.off()


    return {
        link: link
        restrict: "EA"
        require: "ngModel"
        template: template
    }

module.directive("tgEditableSubject", ["$rootScope", "$tgRepo", "$tgConfirm", "$tgLoading", "$tgQueueModelTransformation",
                                       "$tgTemplate", EditableSubjectDirective])

# comments
CommentMedium = (attachmentsFullService) ->
    link = ($scope, $el, $attrs) ->
        $scope.editableDescription = false

        $scope.saveComment = (description, cb) ->
            $scope.content = ''
            $scope.vm.type.comment = description
            $scope.vm.onAddComment({callback: cb})

        types = {
            userstories: "us",
            issues: "issue",
            tasks: "task"
        }

        uploadFile = (file, cb) ->
            return attachmentsFullService.addAttachment($scope.vm.projectId, $scope.vm.type.id, types[$scope.vm.type._name], file).then (result) ->
                cb(result.getIn(['file', 'name']), result.getIn(['file', 'url']))

        $scope.onChange = (markdown) ->
            $scope.vm.type.comment = markdown

        $scope.uploadFiles = (files, cb) ->
            for file in files
                uploadFile(file, cb)

        $scope.content = ''

        $scope.$watch "vm.type", (value) ->
            return if not value

            $scope.storageKey = "comment-" + value.project + "-" + value.id + "-" + value._name

    return {
        scope: true,
        link: link,
        template: """
            <div>
                <tg-medium
                    required
                    not-persist
                    placeholder='{{"COMMENTS.TYPE_NEW_COMMENT" | translate}}'
                    storage-key='storageKey'
                    content='content'
                    on-save='saveComment(text, cb)'
                    on-upload-file='uploadFiles(files, cb)'>
                </tg-medium>
            </div>
        """
    }

module.directive("tgCommentMedium", [
    "tgAttachmentsFullService",
    CommentMedium])

CommentEditMedium = (attachmentsFullService) ->
    link = ($scope, $el, $attrs) ->
        types = {
            userstories: "us",
            issues: "issue",
            tasks: "task"
        }

        console.log $scope.vm

        uploadFile = (file, cb) ->
            console.log $scope.vm
            console.log $scope.vm.projectId
            console.log $scope.vm.comment.comment.id
            console.log types[$scope.vm.comment.comment._name]
            return attachmentsFullService.addAttachment($scope.vm.projectId, $scope.vm.comment.comment.id, types[$scope.vm.comment.comment._name], file).then (result) ->
                cb(result.getIn(['file', 'name']), result.getIn(['file', 'url']))

        $scope.uploadFiles = (files, cb) ->
            for file in files
                uploadFile(file, cb)

    return {
        scope: true,
        link: link,
        template: """
            <div>
                <tg-medium
                    editonly
                    required
                    content='vm.comment.comment'
                    on-save="vm.saveComment(text, cb)"
                    on-cancel="vm.onEditMode({commentId: vm.comment.id})"
                    on-upload-file='uploadFiles(files, cb)'>
                </tg-medium>
            </div>
        """
    }

module.directive("tgCommentEditMedium", [
    "tgAttachmentsFullService",
    CommentEditMedium])

# Used in details descriptions
ItemMedium = ($modelTransform, $rootscope, $confirm, attachmentsFullService, $translate) ->
    link = ($scope, $el, $attrs) ->
        $scope.editableDescription = false

        $scope.saveDescription = (description, cb) ->
            transform = $modelTransform.save (item) ->
                item.description = description

                return item

            transform.then ->
                $confirm.notify("success")
                $rootscope.$broadcast("object:updated")

            transform.then null, ->
                $confirm.notify("error")

            transform.finally ->
                cb()

        uploadFile = (file, cb) ->
            return attachmentsFullService.addAttachment($scope.project.id, $scope.item.id, $attrs.type, file).then (result) ->
                cb(result.getIn(['file', 'name']), result.getIn(['file', 'url']))

        $scope.uploadFiles = (files, cb) ->
            for file in files
                uploadFile(file, cb)

        $scope.$watch $attrs.model, (value) ->
            return if not value
            $scope.item = value
            $scope.version = value.version
            $scope.storageKey = $scope.project.id + "-" + value.id + "-" + $attrs.type

        $scope.$watch 'project', (project) ->
            return if !project

            $scope.editableDescription = project.my_permissions.indexOf($attrs.requiredPerm) != -1

    return {
        scope: true,
        link: link,
        template: """
            <div>
                <tg-medium
                    ng-if="editableDescription"
                    placeholder='{{"COMMON.DESCRIPTION.EMPTY" | translate}}'
                    version='version'
                    storage-key='storageKey'
                    content='item.description'
                    on-save='saveDescription(text, cb)'
                    on-upload-file='uploadFiles(files, cb)'>
                </tg-medium>

                <div
                    class="wysiwyg"
                    ng-if="!editableDescription && item.description.length"
                    ng-bind-html="item.description | markdownToHTML"></div>

                <div
                    class="wysiwyg"
                    ng-if="!editableDescription && !item.description.length">
                    {{'COMMON.DESCRIPTION.NO_DESCRIPTION' | translate}}
                </div>
            </div>
        """
    }

module.directive("tgItemMedium", [
    "$tgQueueModelTransformation",
    "$rootScope",
    "$tgConfirm",
    "tgAttachmentsFullService",
    "$translate",
    ItemMedium])

#############################################################################
## Common list directives
#############################################################################
## NOTE: These directives are used in issues and search and are
##       completely bindonce, they only serves for visualization of data.
#############################################################################

ListItemUsStatusDirective = ->
    link = ($scope, $el, $attrs) ->
        us = $scope.$eval($attrs.tgListitemUsStatus)
        bindOnce $scope, "usStatusById", (usStatusById) ->
            $el.html(usStatusById[us.status].name)

    return {link:link}

module.directive("tgListitemUsStatus", ListItemUsStatusDirective)


ListItemTaskStatusDirective = ->
    link = ($scope, $el, $attrs) ->
        task = $scope.$eval($attrs.tgListitemTaskStatus)
        bindOnce $scope, "taskStatusById", (taskStatusById) ->
            $el.html(taskStatusById[task.status].name)

    return {link:link}

module.directive("tgListitemTaskStatus", ListItemTaskStatusDirective)


ListItemAssignedtoDirective = ($template, $translate, avatarService) ->
    template = $template.get("common/components/list-item-assigned-to-avatar.html", true)

    link = ($scope, $el, $attrs) ->
        bindOnce $scope, "usersById", (usersById) ->
            item = $scope.$eval($attrs.tgListitemAssignedto)
            ctx = {
                name: $translate.instant("COMMON.ASSIGNED_TO.NOT_ASSIGNED"),
            }

            member = usersById[item.assigned_to]
            avatar = avatarService.getAvatar(member)

            ctx.imgurl = avatar.url
            ctx.bg = avatar.bg

            if member
                ctx.name = member.full_name_display

            $el.html(template(ctx))

    return {link:link}

module.directive("tgListitemAssignedto", ["$tgTemplate", "$translate", "tgAvatarService", ListItemAssignedtoDirective])


ListItemIssueStatusDirective = ->
    link = ($scope, $el, $attrs) ->
        issue = $scope.$eval($attrs.tgListitemIssueStatus)
        bindOnce $scope, "issueStatusById", (issueStatusById) ->
            $el.html(issueStatusById[issue.status].name)

    return {link:link}

module.directive("tgListitemIssueStatus", ListItemIssueStatusDirective)


ListItemTypeDirective = ->
    link = ($scope, $el, $attrs) ->
        render = (issueTypeById, issue) ->
            type = issueTypeById[issue.type]
            domNode = $el.find(".level")
            domNode.css("background-color", type.color)
            domNode.attr("title", type.name)

        bindOnce $scope, "issueTypeById", (issueTypeById) ->
            issue = $scope.$eval($attrs.tgListitemType)
            render(issueTypeById, issue)

        $scope.$watch $attrs.tgListitemType, (issue) ->
            render($scope.issueTypeById, issue)

    return {
        link: link
        templateUrl: "common/components/level.html"
    }

module.directive("tgListitemType", ListItemTypeDirective)


ListItemPriorityDirective = ->
    link = ($scope, $el, $attrs) ->
        render = (priorityById, issue) ->
            priority = priorityById[issue.priority]
            domNode = $el.find(".level")
            domNode.css("background-color", priority.color)
            domNode.attr("title", priority.name)

        bindOnce $scope, "priorityById", (priorityById) ->
            issue = $scope.$eval($attrs.tgListitemPriority)
            render(priorityById, issue)

        $scope.$watch $attrs.tgListitemPriority, (issue) ->
            render($scope.priorityById, issue)

    return {
        link: link
        templateUrl: "common/components/level.html"
    }

module.directive("tgListitemPriority", ListItemPriorityDirective)


ListItemSeverityDirective = ->
    link = ($scope, $el, $attrs) ->
        render = (severityById, issue) ->
            severity = severityById[issue.severity]
            domNode = $el.find(".level")
            domNode.css("background-color", severity.color)
            domNode.attr("title", severity.name)

        bindOnce $scope, "severityById", (severityById) ->
            issue = $scope.$eval($attrs.tgListitemSeverity)
            render(severityById, issue)

        $scope.$watch $attrs.tgListitemSeverity, (issue) ->
            render($scope.severityById, issue)

    return {
        link: link
        templateUrl: "common/components/level.html"
    }

module.directive("tgListitemSeverity", ListItemSeverityDirective)


#############################################################################
## Progress bar directive
#############################################################################

TgProgressBarDirective = ($template) ->
    template = $template.get("common/components/progress-bar.html", true)

    render = (el, percentage) ->
        el.html(template({percentage: percentage}))

    link = ($scope, $el, $attrs) ->
        element = angular.element($el)

        $scope.$watch $attrs.tgProgressBar, (percentage) ->
            percentage = _.max([0 , percentage])
            percentage = _.min([100, percentage])
            render($el, percentage)

        $scope.$on "$destroy", ->
            $el.off()

    return {link: link}

module.directive("tgProgressBar", ["$tgTemplate", TgProgressBarDirective])


#############################################################################
## Main title directive
#############################################################################

TgMainTitleDirective = ($translate) ->
    link = ($scope, $el, $attrs) ->
        $attrs.$observe "i18nSectionName", (i18nSectionName) ->
            $scope.sectionName = i18nSectionName

        $scope.$on "$destroy", ->
            $el.off()

    return {
        link: link
        templateUrl: "common/components/main-title.html"
        scope: {
            projectName : "=projectName"
        }
    }

module.directive("tgMainTitle", ["$translate",  TgMainTitleDirective])
