if Meteor.isClient

    Template.menu.helpers
        loggedIn: ->
            true if Meteor.userId()

        userEmail: ->
            Meteor.user().emails[0].address

    Template.menu.events
        'click .button-collapse': ->
            $('.button-collapse').sideNav()

    Template.home.onRendered ->
        $('.slider').slider()

    Template.list.helpers
        datas: ->
            term = Session.get 'listSearch'
            if term isnt undefined
                _.filter crud.find().fetch(), (doc) ->
                    doc.name.toLowerCase().includes(term) or
                    doc.address.toLowerCase().includes term
            else
                crud.find {}, sort: name: 1
        empty: ->
            true if crud.find().fetch().length is 0

        actionable: ->
            true if Meteor.userId()

    Template.list.onRendered ->
        $('.dropdown-button').dropdown()
        

    Template.list.events
        'click .openDeleteModal': ->
            selector = '#deleteModal-' + this._id
            $(selector).openModal()

        'click .doRemove': ->
            Meteor.call 'removeData', this._id
            Materialize.toast 'Data has been deleted.', 4000, 'red'

        'keyup #search': (event) ->
            Session.set 'listSearch', event.target.value.toLowerCase()

        'dblclick .rowData': ->
            if Meteor.userId()
                Router.go '/read/' + this._id

    Template.read.onRendered ->
        Session.set 'addDetail', false
        $('.tooltipped').tooltip delay: 50

    Template.read.helpers
        data: ->
            crud.findOne()
        childs: ->
            child.find {}
        addDetail: ->
            true if Session.get 'addDetail'
        empty: ->
            true if child.find().fetch().length is 0
        myChart: ->
            columnData = [crud.findOne().name]
            childs = child.find().fetch()
            for i in childs
                columnData.push i.amount
            data:
                columns: [columnData],
                type: 'spline'
        totalAmount: ->
            total = 0
            for i in child.find().fetch()
                total += i.amount
            total

    Template.read.events
        'click .addDetail': ->
            Session.set 'addDetail', not Session.get 'addDetail'
        'click .removeDetail': ->
            Meteor.call 'removeDetail', this._id
        'click .print': ->
            childsTable = [['Title', 'Amount']]
            for i in child.find().fetch()
                childsTable.push [i.title, i.amount.toString()]
            person = crud.findOne()
            totalAmount = 0
            for i in child.find().fetch()
                totalAmount += i.amount
            childsTable.push ['Total', totalAmount.toString()]
            pdf = pdfMake.createPdf
                header: 'Data Report'
                footer: 'from Meteor CRUD'
                content: [
                    'Person Name : ' + person.name
                    'Person Age : ' + person.age
                    'Person Address : ' + person.address
                    table:
                        headerRows: 1
                        body: childsTable
                ]
            pdf.open()

    Template.update.helpers
        data: ->
            crud.findOne()

    Template.personMap.onRendered ->
        L.Icon.Default.imagePath = '/packages/bevanhunt_leaflet/images/'
        baseMap = L.tileLayer.provider 'OpenStreetMap.DE'
        map = L.map 'map',
            center: [0.5, 101.44]
            zoom: 10
            layers: [baseMap]
        coord = geocode.getLocation crud.findOne().address, (location) ->
            lat = location.results[0].geometry.location.lat
            lng = location.results[0].geometry.location.lng
            marker = L.marker [lat, lng]
            marker.addTo map
            map.setView [lat, lng], 8
