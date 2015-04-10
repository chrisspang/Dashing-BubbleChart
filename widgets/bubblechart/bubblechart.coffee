class Dashing.Bubblechart extends Dashing.Widget

  ready: ->
    # console.log("Bubblechart READY")
    @svg = null

    if (!@nodes)
      @nodes = []

    @colors = d3.scale.linear()
      .domain([0, 0.5, 1])
      .range(["green", "yellow", "red"])

    @createBubble()
    @updateBubble()

  onData: (value) ->
    # console.log("Bubblechart ONDATA")
    @create_nodes(value.data)
    @updateBubble()

  find_node: (n) =>
    if (!@nodes)
      return []
    for e in @nodes
      if (e.id == n.id)
        return e
    return []
               
  update_node: (d) =>
    n = @find_node(d)
    n.id = d.id
    n.value = d.value
    n.radius = d.radius
    return n

  create_nodes: (data) =>
    @new_nodes = []
    data.forEach (d) =>
      @new_nodes.push @update_node(d)
    @nodes = @new_nodes
        
  createBubble: () ->
    container = $(@node).parent()
    @width = (Dashing.widget_base_dimensions[0] * container.data("sizex")) + Dashing.widget_margins[0] * 2 * (container.data("sizex") - 1) - 40
    @height = (Dashing.widget_base_dimensions[1] * container.data("sizey")) - 60
    @center = {x: @width / 2, y: @height / 2}

    id = @get("id")
    chart = $(@node).find('.bubblechart').get(0)
        
    @svg = d3.select(chart)
      .append("svg")
      .attr("id", id)
      .attr("width", @width)
      .attr("height", @height)

  updateBubble: () ->
    if (!@svg)
      return
                
    selection = @svg.selectAll("g")
      .data(@nodes, (d) -> d.id)

    # console.log(selection)
    # console.log(selection.enter())
    # console.log(selection.exit())

    # Insert new
    g = selection.enter()
      .append("g")
      .attr("class", "node")
      .style("opacity", 1e-6)
      .attr("width", 200)
                
    g.transition()
      .duration(1000)
      .style("opacity", 1)
                                
    g.append("ellipse")
      # .attr("r", (d) -> d.radius)
      .attr("rx", (d) -> d.radius)
      .attr("ry", (d) -> d.radius / 2)
      # .attr("fill", "black")
      # .attr("stroke-width", 2)
      # .attr("stroke", 'black')
      .attr("id", (d) -> "bubble_#{d.id}")

    g.append("text")
      .style("text-anchor", "middle")
      .style("pointer-events", "none")
      .style("class", "nodetitle")
      .attr("transform", (d) -> "translate(0,5)")
      .text( (d) -> d.id )

    # Update
    selection.selectAll("ellipse")
      .transition()
      .duration(1000)
      # .attr("r", (d) -> d.radius)
      .attr("rx", (d) -> d.radius)
      .attr("ry", (d) -> d.radius / 2)
      .attr("fill", (d) => @colors(d.value))

    ## Remove gone nodes
    selection.exit()
      .attr("fill", 'red')
      .transition()
      .duration(1000)
      # .attr("transform", (d) -> "translate(0,0)")
      .remove()

    selection.exit().selectAll("ellipse").transition().duration(1000)
      .attr("rx", 0)
      .attr("ry", 0)

    d3.select(@node)
      .on("mousedown", @mousedown)

    @force = d3.layout.force()
      .nodes(@nodes)
      .size([@width, @height])
      .chargeDistance(400)
      .charge((d) => -Math.pow(d.radius, 2.0) / 4)
      .on "tick", (e) =>
        selection.each(this.move_towards_center(e.alpha))
          .attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")")
      .start()

  move_towards_center: (alpha) =>
    (d) =>
      d.x = d.x + (@center.x - d.x) * 0.3 * alpha
      d.y = d.y + (@center.y - d.y) * 0.3 * alpha

  mousedown: () =>
    for n in @nodes
      n.x += (Math.random() - .5) * 40
      n.y += (Math.random() - .5) * 40
    @force.resume()
